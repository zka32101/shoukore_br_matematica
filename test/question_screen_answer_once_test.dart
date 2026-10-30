import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/question_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

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

Future<void> _drag(WidgetTester tester, String choice) async {
  final from = tester.getCenter(find.byKey(Key('choiceDraggable_$choice'), skipOffstage: false));
  final to = tester.getCenter(find.byKey(const Key('answerDropTarget'), skipOffstage: false));
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.moveTo(to);
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1問に答えたあとは、ドラッグでもう一度答えても、記録は1件のまま', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progressStore = InMemoryProgressStore();
    final growthRepository = await GrowthRepository.load(
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

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: QuestionScreen(
          unit: const Unit(
            id: 'mat_numeros_1',
            subjectId: 'matematica',
            grade: 1,
            titleKey: 'unit_mat_numeros_1',
            templateIds: ['tpl_add_1_10'],
          ),
          source: const _FixedQuestionSource(),
          progressStore: progressStore,
          clock: const SystemClock(),
          questionCache: QuestionCache(),
          growthRepository: growthRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _drag(tester, '5'); // 正解
    expect(find.byKey(const Key('feedbackText'), skipOffstage: false), findsOneWidget);

    await _drag(tester, '7'); // 回答済みなので、受け付けない
    await _drag(tester, '3');

    final attempts = await progressStore.getAttempts('mat_numeros_1');
    expect(attempts, hasLength(1));
    expect(attempts.single.chosenId, '5');
    expect(attempts.single.correct, isTrue);
  });
}
