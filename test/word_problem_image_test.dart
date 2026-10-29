import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/question_screen.dart';
import 'package:shoukore_br_matematica/word_problem_image_resolver.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';

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
      choices: ['5', '7', '9'],
      answer: '7',
      explanationId: 'explanation_add',
      params: {
        'a': '3',
        'b': '4',
        'operator': 'add',
        'wordProblemId': 'word_problem_add_birthday',
      },
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}

void main() {
  test('画像が用意されている文章題IDはアセットパスを返す', () {
    expect(
      wordProblemImageAsset('word_problem_add_birthday'),
      'assets/word_problems/birthday.png',
    );
    expect(wordProblemImageAsset('word_problem_add_fruits'), isNull);
    expect(wordProblemImageAsset(null), isNull);
  });

  testWidgets('画像のある文章題では出題画面にイメージが表示される', (tester) async {
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
            templateIds: ['tpl_add_word_birthday'],
          ),
          source: const _FixedQuestionSource(),
          progressStore: InMemoryProgressStore(),
          clock: const SystemClock(),
          questionCache: QuestionCache(),
          growthRepository: growthRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wordProblemImage'), skipOffstage: false), findsOneWidget);
  });
}
