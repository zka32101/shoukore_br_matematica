import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'growth_repository.dart';
import 'l10n/app_localizations.dart';
import 'question_cache.dart';
import 'question_prompt_resolver.dart';

/// 「親も交わって遊びながら学べる機能」(CLAUDE.md共通要件)。子どもと保護者が
/// 交代で同じ単元の問題に挑戦する5問のミニチャレンジ。子どもの回答は通常の
/// 出題と同様に記録・集計する(学習の実体はそのまま)が、保護者の回答は採点
/// のみで記録しない(保護者の習熟度を測るものではないため)。
class FamilyChallengeScreen extends StatefulWidget {
  const FamilyChallengeScreen({
    super.key,
    required this.unit,
    required this.source,
    required this.progressStore,
    required this.growthRepository,
    required this.clock,
    required this.questionCache,
  });

  final Unit unit;
  final QuestionSource source;
  final ProgressStore progressStore;
  final GrowthRepository growthRepository;
  final Clock clock;
  final QuestionCache questionCache;

  static const totalRounds = 5;

  @override
  State<FamilyChallengeScreen> createState() => _FamilyChallengeScreenState();
}

enum _Turn { child, parent, finished }

class _FamilyChallengeScreenState extends State<FamilyChallengeScreen> {
  int _round = 0;
  int _childScore = 0;
  int _parentScore = 0;
  _Turn _turn = _Turn.child;
  Question? _question;
  String? _feedback;
  String? _lastChosenId;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final targetDifficulty = _turn == _Turn.child
        ? (await widget.progressStore.getMastery(widget.unit.id)).score.clamp(0.3, 1.0)
        : 0.6;
    final question = await widget.source.generate(
      unitId: widget.unit.id,
      targetDifficulty: targetDifficulty == 0 ? 0.5 : targetDifficulty,
    );
    widget.questionCache.register(question);
    if (!mounted) return;
    setState(() {
      _question = question;
      _feedback = null;
      _lastChosenId = null;
    });
  }

  Future<void> _answer(String chosenId) async {
    final question = _question!;
    final correct = widget.source.checkAnswer(question, chosenId);
    if (_turn == _Turn.child) {
      await widget.progressStore.recordAttempt(Attempt(
        questionId: question.id,
        unitId: widget.unit.id,
        correct: correct,
        chosenId: chosenId,
        answeredAt: widget.clock.now(),
      ));
      await widget.growthRepository.recordStudyActivity();
      if (correct) await widget.growthRepository.recordCorrectAnswer();
      if (correct && mounted) setState(() => _childScore++);
    } else {
      if (correct && mounted) setState(() => _parentScore++);
    }
    if (mounted) {
      setState(() {
        _feedback = correct ? 'correct' : 'incorrect';
        _lastChosenId = chosenId;
      });
    }
  }

  Future<void> _nextStep() async {
    if (_turn == _Turn.child) {
      setState(() => _turn = _Turn.parent);
      await _loadQuestion();
      return;
    }
    if (_round + 1 >= FamilyChallengeScreen.totalRounds) {
      setState(() => _turn = _Turn.finished);
      return;
    }
    setState(() {
      _round++;
      _turn = _Turn.child;
    });
    await _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_turn == _Turn.finished) {
      final tie = _childScore == _parentScore;
      final childWon = _childScore > _parentScore;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familyChallengeTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diversity_3, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.familyChallengeResultScore(_childScore, _parentScore),
                  key: const Key('familyChallengeResultText'),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  tie
                      ? l10n.familyChallengeResultTie
                      : childWon
                          ? l10n.familyChallengeResultChildWon
                          : l10n.familyChallengeResultParentWon,
                  key: const Key('familyChallengeResultMessage'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('familyChallengeFinishButton'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.familyChallengeFinishButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _question;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyChallengeTitle)),
      body: question == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.familyChallengeRoundLabel(_round + 1, FamilyChallengeScreen.totalRounds),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    key: const Key('familyChallengeTurnChip'),
                    avatar: Icon(_turn == _Turn.child ? Icons.child_care : Icons.escalator_warning),
                    label: Text(
                      _turn == _Turn.child
                          ? l10n.familyChallengeChildTurn
                          : l10n.familyChallengeParentTurn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final prompt = resolveQuestionPrompt(l10n, question);
                    // 練習画面(question_screen.dart)と同じ、白背景・影付きの
                    // 丸みカードで問題文を表示し、見た目をファミリーチャレンジ
                    // だけ違う印象にならないよう揃える。
                    return Container(
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
                      child: Text(
                        prompt ?? '',
                        key: const Key('familyChallengePromptText'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final choice in question.choices)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FamilyChoiceCard(
                              choiceKey: Key('familyChallengeChoice_$choice'),
                              label: choice,
                              state: _feedback == null
                                  ? _FamilyChoiceState.unanswered
                                  : choice == question.answer
                                      ? _FamilyChoiceState.correct
                                      : choice == _lastChosenId
                                          ? _FamilyChoiceState.incorrectSelected
                                          : _FamilyChoiceState.disabled,
                              onTap: _feedback == null ? () => _answer(choice) : null,
                            ),
                          ),
                        if (_feedback != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            color: _feedback == 'correct'
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    _feedback == 'correct' ? Icons.check_circle : Icons.cancel,
                                    color: _feedback == 'correct'
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _feedback == 'correct'
                                          ? l10n.questionFeedbackCorrect
                                          : l10n.questionFeedbackIncorrect,
                                      key: const Key('familyChallengeFeedbackText'),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: _feedback == 'correct'
                                            ? theme.colorScheme.onPrimaryContainer
                                            : theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('familyChallengeNextButton'),
                            onPressed: _nextStep,
                            child: Text(l10n.familyChallengeNextButton),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

enum _FamilyChoiceState { unanswered, correct, incorrectSelected, disabled }

/// question_screen.dartの_ChoiceCardと同じ見た目・色分けの選択肢カード
/// (ファミリーチャレンジではドラッグ&ドロップ操作は不要なため、
/// Draggable対応は持たない簡略版)。
class _FamilyChoiceCard extends StatelessWidget {
  const _FamilyChoiceCard({
    this.choiceKey,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final Key? choiceKey;
  final String label;
  final _FamilyChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color background;
    Color border;
    Color text;
    switch (state) {
      case _FamilyChoiceState.unanswered:
        background = theme.colorScheme.surface;
        border = theme.colorScheme.outlineVariant;
        text = theme.colorScheme.onSurface;
      case _FamilyChoiceState.correct:
        background = theme.colorScheme.primaryContainer;
        border = theme.colorScheme.primary;
        text = theme.colorScheme.onPrimaryContainer;
      case _FamilyChoiceState.incorrectSelected:
        background = theme.colorScheme.errorContainer;
        border = theme.colorScheme.error;
        text = theme.colorScheme.onErrorContainer;
      case _FamilyChoiceState.disabled:
        background = theme.colorScheme.surface;
        border = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
        text = theme.colorScheme.onSurfaceVariant;
    }
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

