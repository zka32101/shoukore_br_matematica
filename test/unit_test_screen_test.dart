import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/unit_test_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';

/// まとめテスト画面の検証用に、常に同じ問題を返す最小構成のQuestionSource。
/// 正解の選択肢(`5`)を選び続ければ満点、不正解(`3`)を選び続ければ0点になる。
class _FixedQuestionSource implements QuestionSource {
  const _FixedQuestionSource();

  @override
  Future<List<Unit>> loadUnits(String locale) async => const [];

  @override
  Future<Question> generate({required String unitId, required double targetDifficulty}) async {
    return const Question(
      id: 'q_fixed',
      unitId: 'mat_numeros_1',
      type: QuestionType.choice,
      difficulty: 0.5,
      choices: ['3', '5', '7'],
      answer: '5',
      explanationId: 'explanation_add',
      params: {'a': '2', 'b': '3', 'operator': 'add'},
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}

void main() {
  Future<GrowthRepository> loadGrowthRepository() => GrowthRepository.load(
    clock: const SystemClock(),
    profile: const RegionalProfile(
      locale: 'pt_BR',
      ageOfConsent: 13,
      guardianConsentRequired: true,
      dailyResetHour: 5,
      timeZone: 'America/Sao_Paulo',
      screenTimeLimitMinutes: 0,
      profilingAdsAllowed: false,
    ),
    store: InMemoryGrowthStore(),
  );

  const unit = Unit(
    id: 'mat_numeros_1',
    subjectId: 'matematica',
    grade: 1,
    titleKey: 'unit_mat_numeros_1',
    templateIds: ['tpl_add_1_10'],
  );

  Future<void> answerAll(WidgetTester tester, String choiceLabel) async {
    for (var i = 0; i < UnitTestScreen.totalQuestions; i++) {
      await tester.tap(find.byKey(Key('unitTestChoice_$choiceLabel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unitTestNextButton')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('全問正解すると合格と表示される', (tester) async {
    final growthRepository = await loadGrowthRepository();
    final progressStore = InMemoryProgressStore();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: UnitTestScreen(
          unit: unit,
          source: const _FixedQuestionSource(),
          progressStore: progressStore,
          growthRepository: growthRepository,
          clock: const SystemClock(),
          questionCache: QuestionCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('unitTestQuestionLabel')),
      findsOneWidget,
    );

    await answerAll(tester, '5');

    expect(find.byKey(const Key('unitTestPassedIcon')), findsOneWidget);
    expect(
      find.text('Você acertou 10 de 10'),
      findsOneWidget,
    );

    // 記録されたAttemptはすべてmode:'test'で、合否判定に使える。
    final attempts = await progressStore.getAttempts(unit.id);
    expect(attempts.length, UnitTestScreen.totalQuestions);
    expect(attempts.every((a) => a.mode == 'test'), isTrue);
    expect(
      UnitTestScreen.eligibility.isPassed(attempts),
      isTrue,
    );
  });

  testWidgets('全問不正解だと不合格と表示される', (tester) async {
    final growthRepository = await loadGrowthRepository();
    final progressStore = InMemoryProgressStore();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: UnitTestScreen(
          unit: unit,
          source: const _FixedQuestionSource(),
          progressStore: progressStore,
          growthRepository: growthRepository,
          clock: const SystemClock(),
          questionCache: QuestionCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await answerAll(tester, '3');

    expect(find.byKey(const Key('unitTestFailedIcon')), findsOneWidget);
    expect(find.text('Você acertou 0 de 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unitTestFinishButton')));
    await tester.pumpAndSettle();
  });
}
