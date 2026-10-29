import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/question_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';

/// 体験型コンテンツ(ドラッグ&ドロップ回答)の検証用に、常に同じ問題を返す
/// 最小構成のQuestionSource。
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
  testWidgets('選択肢をドラッグして回答エリアにドロップすると正誤判定される', (tester) async {
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
          progressStore: InMemoryProgressStore(),
          clock: const SystemClock(),
          questionCache: QuestionCache(),
          growthRepository: growthRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ドラッグ&ドロップの回答エリアが表示されている。
    expect(find.byKey(const Key('answerDropTarget'), skipOffstage: false), findsOneWidget);

    // 正解(5)をドラッグして回答エリアまで運ぶと、正誤判定(feedbackText)が表示される。
    final choiceCenter = tester.getCenter(
      find.byKey(const Key('choiceDraggable_5'), skipOffstage: false),
    );
    final targetCenter = tester.getCenter(
      find.byKey(const Key('answerDropTarget'), skipOffstage: false),
    );
    final gesture = await tester.startGesture(choiceCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(targetCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedbackText'), skipOffstage: false), findsOneWidget);
  });
}
