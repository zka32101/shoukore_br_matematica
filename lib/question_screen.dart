import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'answer_feedback_animation.dart';
import 'dataset_bar_chart.dart';
import 'explanation_resolver.dart';
import 'growth_repository.dart';
import 'growth_stage_label_resolver.dart';
import 'l10n/app_localizations.dart';
import 'math_guide_screen.dart';
import 'misconception_hint_resolver.dart';
import 'question_cache.dart';
import 'question_prompt_resolver.dart';
import 'sequence_term_strip.dart';
import 'shape_tap_counter.dart';
import 'tts_service.dart';
import 'unit_name_resolver.dart';
import 'unit_tally_counter.dart';
import 'weekly_challenge_repository.dart';
import 'word_problem_image_resolver.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({
    super.key,
    required this.unit,
    required this.source,
    required this.progressStore,
    required this.clock,
    required this.questionCache,
    required this.growthRepository,
    this.weeklyChallengeRepository,
    this.notificationScheduler,
  });

  final Unit unit;
  final QuestionSource source;
  final ProgressStore progressStore;
  final Clock clock;
  final QuestionCache questionCache;
  final GrowthRepository growthRepository;

  /// 未指定時(単体テスト等)はウィークリーチャレンジの更新を行わない。
  final WeeklyChallengeRepository? weeklyChallengeRepository;

  /// 3連続不正解時に保護者向けアラートを通知スケジュールにも連携する。
  /// 未指定時(単体テスト等)はSnackBar表示のみに留める。
  final NotificationScheduler? notificationScheduler;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  static const _weakNotesAnalyzer = WeakNotesAnalyzer();
  static const _autoHintPolicy = AutoHintPolicy();
  static const _consecutiveIncorrectAlert = ConsecutiveIncorrectAnswerAlert();

  final TtsService _ttsService = TtsService();

  Question? _question;
  Mastery? _mastery;
  String? _feedback;
  String? _overcomeMisconception;
  String? _misconceptionHint;
  bool _autoHintVisible = false;
  bool _consecutiveIncorrectAlertShown = false;
  int _answerAttemptSequence = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    final mastery = await widget.progressStore.getMastery(widget.unit.id);
    final question = await widget.source.generate(
      unitId: widget.unit.id,
      targetDifficulty: mastery.score == 0 ? 0.5 : mastery.score,
    );
    widget.questionCache.register(question);
    setState(() {
      _question = question;
      _mastery = mastery;
      _feedback = null;
      _misconceptionHint = null;
      _autoHintVisible = _autoHintPolicy.shouldShowHint(mastery);
    });
  }

  Future<void> _answer(String chosenId) async {
    final question = _question!;
    final correct = widget.source.checkAnswer(question, chosenId);
    await widget.progressStore.recordAttempt(Attempt(
      questionId: question.id,
      unitId: widget.unit.id,
      correct: correct,
      chosenId: chosenId,
      answeredAt: widget.clock.now(),
    ));
    await widget.growthRepository.recordStudyActivity();
    if (correct) {
      await widget.growthRepository.recordCorrectAnswer();
      await widget.weeklyChallengeRepository?.recordCorrectAnswer();
    }
    final mastery = await widget.progressStore.getMastery(widget.unit.id);

    // 直近の誤解傾向から最頻出タイプを求め、それを克服済み（直近N問連続正解かつ
    // それ以前に同タグの誤答があった）と判定できればバッジ表示する。
    final attempts = await widget.progressStore.getAttempts(widget.unit.id);
    final note = _weakNotesAnalyzer.analyze(
      unitId: widget.unit.id,
      attempts: attempts,
      questionLookup: widget.questionCache.lookup,
    );
    final topMisconception = _weakNotesAnalyzer.topMisconception(note);
    final overcome = topMisconception != null &&
        _weakNotesAnalyzer.isOvercome(
          attemptsNewestFirst: attempts,
          questionLookup: widget.questionCache.lookup,
          misconceptionTag: topMisconception,
        );

    String? misconceptionHint;
    final misconceptionTag = question.misconceptionTags[chosenId];
    if (!correct && misconceptionTag != null && mounted) {
      misconceptionHint = resolveMisconceptionHint(AppLocalizations.of(context)!, misconceptionTag);
    }

    if (!correct &&
        !_consecutiveIncorrectAlertShown &&
        _consecutiveIncorrectAlert.shouldAlert(attempts) &&
        mounted) {
      _consecutiveIncorrectAlertShown = true;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('consecutiveIncorrectAlertSnackBar'),
          content: Text('${l10n.consecutiveIncorrectAlertTitle}: '
              '${l10n.consecutiveIncorrectAlertMessage}'),
        ),
      );
      // 保護者がアプリを開いていなくても気付けるよう、通知スケジュールにも
      // 連携する(実機プッシュ連携は別途、このスケジューラの後継アダプタで対応)。
      await widget.notificationScheduler?.schedule(
        id: 'guardian_alert_${widget.unit.id}',
        at: widget.clock.now(),
        titleKey: 'consecutiveIncorrectAlertTitle',
        bodyKey: 'consecutiveIncorrectAlertMessage',
      );
    }

    setState(() {
      _feedback = correct ? 'correct' : 'incorrect';
      _mastery = mastery;
      _overcomeMisconception = overcome ? topMisconception : null;
      _misconceptionHint = misconceptionHint;
      _answerAttemptSequence++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _question;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final correct = _feedback == 'correct';
    return Scaffold(
      appBar: AppBar(title: Text(resolveUnitName(l10n, widget.unit.id))),
      body: question == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_mastery != null)
                          Row(
                            children: [
                              Icon(Icons.insights, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                l10n.questionMasteryLabel(
                                  (_mastery!.score * 100).round(),
                                ),
                                key: const Key('masteryText'),
                                style: theme.textTheme.titleSmall,
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.questionGrowthStatusLine(
                            growthStageLabel(widget.growthRepository.stage),
                            widget.growthRepository.wallet.balance,
                            widget.growthRepository.missionState.completedCount,
                            widget.growthRepository.streak.currentStreakDays,
                          ),
                          key: const Key('growthStatusText'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                // KeyedSubtree: 条件付きで出現/消滅するリスト項目にはKeyを付け、
                // Flutterが位置ベースで無関係な要素の状態を取り違えないようにする。
                KeyedSubtree(
                  key: const ValueKey('promptSlot'),
                  child: Builder(builder: (context) {
                    final prompt = resolveQuestionPrompt(
                      AppLocalizations.of(context)!,
                      question,
                    );
                    if (prompt == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              prompt,
                              key: const Key('questionPromptText'),
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            key: const Key('listenPromptButton'),
                            tooltip: AppLocalizations.of(context)!.listenButtonLabel,
                            icon: const Icon(Icons.volume_up_outlined),
                            onPressed: () => _ttsService.speak(prompt),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                // 文章題にイメージ画像があれば表示する(わかりやすいイメージ画像)。
                // アセットが見つからない環境でも落ちないよう、読み込み失敗時は
                // 何も表示しない(テキストのみの表示にフォールバック)。
                if (wordProblemImageAsset(question.params['wordProblemId']) != null)
                  KeyedSubtree(
                    key: ValueKey('wordProblemImageSlot_${question.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          wordProblemImageAsset(question.params['wordProblemId'])!,
                          key: const Key('wordProblemImage'),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                // 体験型コンテンツ: 図形問題では、辺を1つずつタップして数える
                // 補助ウィジェットを表示する(正誤判定は既存の選択肢/ドラッグ&
                // ドロップが担う。これはあくまで「数える」体験のための見た目)。
                if (question.params.containsKey('sides'))
                  KeyedSubtree(
                    key: ValueKey('shapeTapCounterSlot_${question.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ShapeTapCounter(
                        sides: int.parse(question.params['sides']!),
                      ),
                    ),
                  ),
                // 体験型コンテンツ: 測定(単位変換)問題では、タイルを1つずつ
                // タップして数の大きさを実感できる補助ウィジェットを表示する。
                if (question.params.containsKey('fromUnitKey') &&
                    question.params.containsKey('value'))
                  KeyedSubtree(
                    key: ValueKey('unitTallyCounterSlot_${question.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: UnitTallyCounter(
                        count: int.parse(question.params['value']!).clamp(1, 20),
                      ),
                    ),
                  ),
                // 体験型コンテンツ: 数列問題では、既出の項を並べて見せ、
                // パターンの続きを考える体験を視覚化する。
                if (question.params.containsKey('terms'))
                  KeyedSubtree(
                    key: ValueKey('sequenceTermStripSlot_${question.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SequenceTermStrip(
                        terms: question.params['terms']!.split(','),
                      ),
                    ),
                  ),
                // 体験型コンテンツ: データ分析問題では、棒グラフとして値を
                // 可視化し、バーをタップしても回答できるようにする。
                if (question.params.containsKey('values') &&
                    question.params.containsKey('operation'))
                  KeyedSubtree(
                    key: ValueKey('datasetBarChartSlot_${question.id}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: DatasetBarChart(
                        values: question.params['values']!
                            .split(',')
                            .map(int.parse)
                            .toList(),
                        onBarTap: _answer,
                      ),
                    ),
                  ),
                if (_autoHintVisible && question.explanationId.isNotEmpty)
                  KeyedSubtree(
                    key: const ValueKey('autoHintSlot'),
                    child: Builder(builder: (context) {
                    final hint = resolveExplanation(
                      AppLocalizations.of(context)!,
                      question.explanationId,
                    );
                    if (hint == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: theme.colorScheme.onSecondaryContainer),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hint,
                                  key: const Key('autoHintText'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  ),
                const SizedBox(height: 20),
                // 体験型コンテンツ: 選択肢をタップするだけでなく、指でドラッグして
                // 答えの入れ物まで運ぶことでも回答できる(実際に手を動かす感覚)。
                // タップでの回答も引き続き有効(低年齢児や端末操作の個人差に配慮)。
                DragTarget<String>(
                  onAcceptWithDetails: (details) => _answer(details.data),
                  builder: (context, candidateData, rejectedData) {
                    final highlighted = candidateData.isNotEmpty;
                    return Container(
                      key: const Key('answerDropTarget'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: highlighted
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: highlighted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.move_down,
                            color: highlighted
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.dragDropTargetLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: highlighted
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final choice in question.choices)
                      Draggable<String>(
                        key: Key('choiceDraggable_$choice'),
                        data: choice,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 140,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                textStyle: theme.textTheme.titleMedium,
                              ),
                              child: Text(choice),
                            ),
                          ),
                        ),
                        childWhenDragging: SizedBox(
                          width: 140,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              textStyle: theme.textTheme.titleMedium,
                            ),
                            child: Text(choice),
                          ),
                        ),
                        child: SizedBox(
                          width: 140,
                          height: 56,
                          child: ElevatedButton(
                            key: Key('choice_$choice'),
                            onPressed: () => _answer(choice),
                            style: ElevatedButton.styleFrom(
                              textStyle: theme.textTheme.titleMedium,
                            ),
                            child: Text(choice),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_feedback != null) ...[
                  const SizedBox(height: 20),
                  AnswerFeedbackAnimation(
                    key: ValueKey('answerFeedbackAnimation_$_answerAttemptSequence'),
                    correct: correct,
                    child: Card(
                      color: correct
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              correct ? Icons.check_circle : Icons.cancel,
                              color: correct
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              correct ? l10n.questionFeedbackCorrect : l10n.questionFeedbackIncorrect,
                              key: const Key('feedbackText'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: correct
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (_misconceptionHint != null)
                  KeyedSubtree(
                    key: const ValueKey('misconceptionHintSlot'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _misconceptionHint!,
                                  key: const Key('misconceptionHintText'),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_feedback != null && question.explanationId.isNotEmpty)
                  KeyedSubtree(
                    key: const ValueKey('explanationSlot'),
                    child: Builder(builder: (context) {
                      final explanation = resolveExplanation(
                        AppLocalizations.of(context)!,
                        question.explanationId,
                      );
                      if (explanation == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.explanationSectionTitle,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key('listenExplanationButton'),
                                      tooltip: AppLocalizations.of(context)!.listenButtonLabel,
                                      icon: const Icon(Icons.volume_up_outlined),
                                      onPressed: () => _ttsService.speak(explanation),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(explanation, key: const Key('explanationText')),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                if (_overcomeMisconception != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Chip(
                      avatar: const Icon(Icons.emoji_events, size: 18),
                      label: Text(
                        AppLocalizations.of(context)!.misconceptionOvercome(_overcomeMisconception!),
                        key: const Key('misconceptionOvercomeBadge'),
                      ),
                    ),
                  ),
                // 体験型コンテンツ(ゲーム)が終わったら、自然に次の行動へ誘導する。
                // 不正解の時は教科書解説(MathGuideScreen)への導線を添えて、
                // 「もう一度挑戦する前に解説を見る」流れを作る。正解の時は
                // そのまま次の問題で遊び続けられるようにする。
                if (_feedback == 'incorrect')
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      l10n.incorrectAnswerGuideNudge,
                      key: const Key('incorrectAnswerGuideNudgeText'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('nextQuestionButton'),
                        onPressed: _loadQuestion,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(l10n.nextQuestionButton),
                      ),
                    ),
                    if (_feedback == 'incorrect') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('openMathGuideButton'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MathGuideScreen()),
                          ),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(l10n.openMathGuideButton),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}
