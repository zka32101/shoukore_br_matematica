import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/question_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';

/// 体験型コンテンツ(測定/数列/データ分析)の検証用に、指定した問題を
/// 固定で返す最小構成のQuestionSource。
class _FixedQuestionSource implements QuestionSource {
  const _FixedQuestionSource(this.question);

  final Question question;

  @override
  Future<List<Unit>> loadUnits(String locale) async => const [];

  @override
  Future<Question> generate({required String unitId, required double targetDifficulty}) async =>
      question;

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}

Future<GrowthRepository> _growthRepository() => GrowthRepository.load(
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

Future<void> _pumpQuestionScreen(WidgetTester tester, Question question) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      home: QuestionScreen(
        unit: Unit(
          id: question.unitId,
          subjectId: 'matematica',
          grade: 1,
          titleKey: 'unit_${question.unitId}',
          templateIds: const ['tpl'],
        ),
        source: _FixedQuestionSource(question),
        progressStore: InMemoryProgressStore(),
        clock: const SystemClock(),
        questionCache: QuestionCache(),
        growthRepository: await _growthRepository(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('測定問題はタイルをタップして数えられる', (tester) async {
    await _pumpQuestionScreen(
      tester,
      const Question(
        id: 'q_measure',
        unitId: 'mat_grandezas_1',
        type: QuestionType.choice,
        difficulty: 0.5,
        choices: ['300', '400', '500'],
        answer: '400',
        explanationId: 'explanation_unit_cm_to_m',
        params: {'fromUnitKey': 'unit_m', 'toUnitKey': 'unit_cm', 'value': '4', 'factor': '100'},
      ),
    );

    expect(find.byKey(const Key('unitTallyTile_0'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('unitTallyTile_3'), skipOffstage: false), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('unitTallyTile_0'), skipOffstage: false));
    await tester.tap(find.byKey(const Key('unitTallyTile_0'), skipOffstage: false));
    await tester.pumpAndSettle();
    expect(
      find.text('Você contou 1!', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('数列問題は既出の項と?が並んで表示される', (tester) async {
    await _pumpQuestionScreen(
      tester,
      const Question(
        id: 'q_sequence',
        unitId: 'mat_algebra_1',
        type: QuestionType.choice,
        difficulty: 0.5,
        choices: ['4', '5', '6'],
        answer: '5',
        explanationId: 'explanation_sequence',
        params: {'terms': '1,2,3,4'},
      ),
    );

    for (var i = 0; i < 4; i++) {
      expect(find.byKey(Key('sequenceTerm_$i'), skipOffstage: false), findsOneWidget);
    }
    expect(find.byKey(const Key('sequenceTermQuestionMark'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('データ分析問題は棒グラフのバーをタップしても回答できる', (tester) async {
    await _pumpQuestionScreen(
      tester,
      const Question(
        id: 'q_dataset',
        unitId: 'mat_probabilidade_1',
        type: QuestionType.choice,
        difficulty: 0.5,
        choices: ['3', '7', '10'],
        answer: '10',
        explanationId: 'explanation_dataset_max',
        params: {'values': '3,7,10', 'operation': 'max'},
      ),
    );

    expect(find.byKey(const Key('datasetBar_2'), skipOffstage: false), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('datasetBar_2'), skipOffstage: false));
    await tester.tap(find.byKey(const Key('datasetBar_2'), skipOffstage: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedbackText'), skipOffstage: false), findsOneWidget);
  });
}
