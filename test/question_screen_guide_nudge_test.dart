import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/math_guide_screen.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/question_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';

/// 不正解時に教科書解説(MathGuideScreen)への導線を表示するための、
/// 常に不正解になる最小構成のQuestionSource。
class _AlwaysWrongQuestionSource implements QuestionSource {
  const _AlwaysWrongQuestionSource();

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
  bool checkAnswer(Question question, String chosenId) => false;
}

void main() {
  testWidgets('不正解時は教科書解説への導線が表示され、タップするとMathGuideScreenが開く', (tester) async {
    // 選択肢カードがJP版同様に縦に並ぶ大きな丸みカードになり縦幅が伸びたため、
    // 既定のテストビューポートでは全項目がスクロールなしで収まらない。
    // スクロール操作に頼ると遅延レイアウトの罠(CLAUDE.md記載)を踏みやすいため、
    // ここではビューポート自体を縦に広げて全項目を一度に描画させる。
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          source: const _AlwaysWrongQuestionSource(),
          progressStore: InMemoryProgressStore(),
          clock: const SystemClock(),
          questionCache: QuestionCache(),
          growthRepository: growthRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 正解していない間は導線が表示されない。
    expect(
      find.byKey(const Key('openMathGuideButton'), skipOffstage: false),
      findsNothing,
    );

    // 選択肢カードがJP版同様に縦に並ぶ大きな丸みカードになったことで
    // 縦幅が伸び、小さいテストビューポートではensureVisibleだけでは
    // スクロールしきれないことがあるため、scrollUntilVisibleを使う。
    await tester.scrollUntilVisible(
      find.byKey(const Key('choice_3'), skipOffstage: false),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choice_3'), skipOffstage: false));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('incorrectAnswerGuideNudgeText'), skipOffstage: false),
      findsOneWidget,
    );
    // 回答後のボタン群はListViewのSliver遅延レイアウトでcacheExtent外に
    // あることがあるため、見つかるまでスクロールする。
    await tester.scrollUntilVisible(
      find.byKey(const Key('openMathGuideButton'), skipOffstage: false),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('openMathGuideButton'), skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('openMathGuideButton'), skipOffstage: false),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(MathGuideScreen), findsOneWidget);
  });
}
