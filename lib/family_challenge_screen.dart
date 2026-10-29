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
    if (mounted) setState(() => _feedback = correct ? 'correct' : 'incorrect');
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
                    return Text(
                      prompt ?? '',
                      key: const Key('familyChallengePromptText'),
                      style: theme.textTheme.headlineSmall,
                    );
                  }),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final choice in question.choices)
                        SizedBox(
                          width: 140,
                          height: 56,
                          child: ElevatedButton(
                            key: Key('familyChallengeChoice_$choice'),
                            onPressed: _feedback == null ? () => _answer(choice) : null,
                            child: Text(choice),
                          ),
                        ),
                    ],
                  ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _feedback == 'correct'
                          ? l10n.questionFeedbackCorrect
                          : l10n.questionFeedbackIncorrect,
                      key: const Key('familyChallengeFeedbackText'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('familyChallengeNextButton'),
                      onPressed: _nextStep,
                      child: Text(l10n.familyChallengeNextButton),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

