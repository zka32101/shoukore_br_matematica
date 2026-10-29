import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'growth_repository.dart';
import 'l10n/app_localizations.dart';
import 'question_cache.dart';
import 'question_prompt_resolver.dart';

/// 単元の「まとめテスト」(到達点モード)。無限に出題される通常の練習とは
/// 別に、固定[totalQuestions]問・1回勝負で単元への理解度を測る。
/// 回答は`Attempt.mode: 'test'`で記録し(通常の練習記録とは区別しつつ、
/// 学習ストリーク・ミッション進捗には通常通り反映する)、直近のテスト
/// 結果だけで合否を判定する(コア側`UnitTestPassEligibility`)。
class UnitTestScreen extends StatefulWidget {
  const UnitTestScreen({
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

  static const totalQuestions = 10;
  static const eligibility = UnitTestPassEligibility(
    requiredQuestions: totalQuestions,
    passAccuracy: 0.8,
  );

  @override
  State<UnitTestScreen> createState() => _UnitTestScreenState();
}

class _UnitTestScreenState extends State<UnitTestScreen> {
  int _questionIndex = 0;
  int _score = 0;
  bool _finished = false;
  Question? _question;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    // まとめテストは一定の難度を保つため、通常練習の習熟度に左右されない
    // 固定の難易度を使う(易しすぎても到達点の確認にならないため)。
    final question = await widget.source.generate(unitId: widget.unit.id, targetDifficulty: 0.6);
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
    await widget.progressStore.recordAttempt(
      Attempt(
        questionId: question.id,
        unitId: widget.unit.id,
        correct: correct,
        chosenId: chosenId,
        answeredAt: widget.clock.now(),
        mode: 'test',
      ),
    );
    await widget.growthRepository.recordStudyActivity();
    if (correct) await widget.growthRepository.recordCorrectAnswer();
    if (!mounted) return;
    setState(() {
      _feedback = correct ? 'correct' : 'incorrect';
      if (correct) _score++;
    });
  }

  Future<void> _nextStep() async {
    if (_questionIndex + 1 >= UnitTestScreen.totalQuestions) {
      setState(() => _finished = true);
      return;
    }
    setState(() => _questionIndex++);
    await _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_finished) {
      final passed = _score / UnitTestScreen.totalQuestions >=
          UnitTestScreen.eligibility.passAccuracy;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.unitTestTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  passed ? Icons.verified : Icons.refresh,
                  key: Key(passed ? 'unitTestPassedIcon' : 'unitTestFailedIcon'),
                  size: 64,
                  color: passed ? Colors.amber[800] : theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.unitTestResultScore(_score, UnitTestScreen.totalQuestions),
                  key: const Key('unitTestResultText'),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  passed ? l10n.unitTestResultPassed : l10n.unitTestResultFailed,
                  key: const Key('unitTestResultMessage'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('unitTestFinishButton'),
                  onPressed: () => Navigator.of(context).pop(passed),
                  child: Text(l10n.unitTestFinishButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _question;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.unitTestTitle)),
      body: question == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.unitTestQuestionLabel(
                      _questionIndex + 1,
                      UnitTestScreen.totalQuestions,
                    ),
                    key: const Key('unitTestQuestionLabel'),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _questionIndex / UnitTestScreen.totalQuestions,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Builder(
                    builder: (context) {
                      final prompt = resolveQuestionPrompt(l10n, question);
                      return Text(
                        prompt ?? '',
                        key: const Key('unitTestPromptText'),
                        style: theme.textTheme.headlineSmall,
                      );
                    },
                  ),
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
                            key: Key('unitTestChoice_$choice'),
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
                      key: const Key('unitTestFeedbackText'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      key: const Key('unitTestNextButton'),
                      onPressed: _nextStep,
                      child: Text(
                        _questionIndex + 1 >= UnitTestScreen.totalQuestions
                            ? l10n.unitTestSeeResultButton
                            : l10n.unitTestNextButton,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
