import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _consecutiveIncorrectAlert = ConsecutiveIncorrectAnswerAlert();

  final TtsService _ttsService = TtsService();

  Question? _question;
  Mastery? _mastery;
  String? _feedback;
  // 回答後、選んだ選択肢を強調表示するために保持する(正誤判定自体は
  // コア側のcheckAnswerが行うが、見た目の色分けにはどれを選んだかが要る)。
  String? _lastChosenId;
  String? _overcomeMisconception;
  String? _misconceptionHint;
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
      _lastChosenId = null;
      _misconceptionHint = null;
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
      _lastChosenId = chosenId;
      _mastery = mastery;
      _overcomeMisconception = overcome ? topMisconception : null;
      _misconceptionHint = misconceptionHint;
      _answerAttemptSequence++;
    });
    // 触覚フィードバック: 画面を見ていなくても回答の手応えを感じられる
    // ようにする(正解は弾む強め、不正解は控えめな振動)。
    unawaited(correct ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact());
  }

  @override
  Widget build(BuildContext context) {
    final question = _question;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final correct = _feedback == 'correct';
    return Scaffold(
      appBar: AppBar(title: Text(resolveUnitName(l10n, widget.unit.id))),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: question == null
            ? const Center(
                key: ValueKey('questionLoading'),
                child: CircularProgressIndicator(),
              )
            : ListView(
              key: const ValueKey('questionLoaded'),
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
                            growthStageLabel(l10n, widget.growthRepository.stage),
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
                    // JP版と同様、問題文は白背景・影付きの丸みカードに大きく
                    // 中央揃えで表示する(「わかりやすい丁寧な解説」要件に合わせ、
                    // 問題文自体の視認性を高める)。
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              prompt,
                              key: const Key('questionPromptText'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            IconButton(
                              key: const Key('listenPromptButton'),
                              tooltip: AppLocalizations.of(context)!.listenButtonLabel,
                              icon: const Icon(Icons.volume_up_outlined),
                              onPressed: () => _ttsService.speak(prompt),
                            ),
                          ],
                        ),
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
                // JP版と同様、選択肢は横一列ではなく縦に並ぶ大きな丸みカード
                // にする(タップ面積を確保し、低年齢児でも押しやすくする)。
                // 正誤が分かった後は選んだ肢と正解の肢を色分けして表示する
                // (JP版の「選んだ誤答=強調/正解=緑」の見せ方を踏襲)。
                Column(
                  children: [
                    for (final choice in question.choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Draggable<String>(
                          key: Key('choiceDraggable_$choice'),
                          data: choice,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 200,
                              child: _ChoiceCard(
                                label: choice,
                                state: _ChoiceState.unanswered,
                                onTap: null,
                              ),
                            ),
                          ),
                          childWhenDragging: _ChoiceCard(
                            label: choice,
                            state: _ChoiceState.unanswered,
                            onTap: null,
                          ),
                          child: _ChoiceCard(
                            choiceKey: Key('choice_$choice'),
                            label: choice,
                            state: _feedback == null
                                ? _ChoiceState.unanswered
                                : choice == question.answer
                                    ? _ChoiceState.correct
                                    : choice == _lastChosenId
                                        ? _ChoiceState.incorrectSelected
                                        : _ChoiceState.disabled,
                            onTap: _feedback == null ? () => _answer(choice) : null,
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
                            Expanded(
                              child: Text(
                                correct ? l10n.questionFeedbackCorrect : l10n.questionFeedbackIncorrect,
                                key: const Key('feedbackText'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: correct
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                ),
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
      ),
    );
  }
}

enum _ChoiceState { unanswered, correct, incorrectSelected, disabled }

/// JP版と同様の、縦に並ぶ大きな丸みのある選択肢カード。アプリの単一シード色
/// 方針(primary/secondary/tertiaryのトーンで統一)に沿い、固定の色相を
/// 追加するのではなくテーマのロールで状態を表す
/// (正解=primaryContainer、選んだ誤答=errorContainer)。
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    this.choiceKey,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final Key? choiceKey;
  final String label;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color background;
    Color border;
    Color text;
    switch (state) {
      case _ChoiceState.unanswered:
        background = theme.colorScheme.surface;
        border = theme.colorScheme.outlineVariant;
        text = theme.colorScheme.onSurface;
      case _ChoiceState.correct:
        background = theme.colorScheme.primaryContainer;
        border = theme.colorScheme.primary;
        text = theme.colorScheme.onPrimaryContainer;
      case _ChoiceState.incorrectSelected:
        background = theme.colorScheme.errorContainer;
        border = theme.colorScheme.error;
        text = theme.colorScheme.onErrorContainer;
      case _ChoiceState.disabled:
        background = theme.colorScheme.surface;
        border = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
        text = theme.colorScheme.onSurfaceVariant;
    }
    // Draggableの子として使うため、素のGestureDetectorではなく
    // ElevatedButtonと同じMaterial+InkWell構成にする(ジェスチャーアリーナで
    // ドラッグ認識と確実に共存させるため)。
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: choiceKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ),
      ),
    );
  }
}
