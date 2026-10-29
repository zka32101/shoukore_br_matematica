import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/question_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';

/// 「ゲームで学ぶ」のゲーム性(セッション中の正解数・連続正解の可視化、
/// 離脱時の振り返りダイアログ)を検証するための、常に同じ問題を返す
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

  testWidgets('ゲームセッション中は正解数・連続正解(コンボ)のステータスバーが更新される', (tester) async {
    // 選択肢カードがJP版同様に縦に並ぶ大きな丸みカードになり縦幅が伸びた
    // うえ、ゲームセッション用のステータスバーも加わったため、既定の
    // テストビューポートでは全項目がスクロールなしで収まらない。
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final growthRepository = await loadGrowthRepository();

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
          isGameSession: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 通常の単元学習画面では出さないステータスバーが、ゲームセッションでは
    // 画面上部に表示される。
    expect(find.byKey(const Key('gameSessionStatsBar')), findsOneWidget);
    expect(find.byKey(const Key('gameSessionStreakValue')), findsOneWidget);

    // 正解(5)を選ぶと、連続正解(コンボ)が1になる。
    await tester.tap(find.byKey(const Key('choice_5')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('gameSessionStreakValue')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('nextQuestionButton')));
    await tester.pumpAndSettle();

    // 不正解(3)を選ぶと、連続正解(コンボ)は0に戻る。
    await tester.tap(find.byKey(const Key('choice_3')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('gameSessionStreakValue')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ゲームセッション中に戻ろうとすると、今回の記録を振り返るダイアログが出る', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final growthRepository = await loadGrowthRepository();

    // PopScopeのBackButtonが実際に描画されるよう(canPopがtrueになるよう)、
    // 下敷きとなる画面からQuestionScreenをpushする構成にする。
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('openQuestionScreenButton'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuestionScreen(
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
                      isGameSession: true,
                    ),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openQuestionScreenButton')));
    await tester.pumpAndSettle();

    // まだ1問も答えていない間は、確認なしでそのまま戻れる
    // (離脱時の振り返りは「遊んだ記録」があるときだけ意味があるため)。
    expect(find.byKey(const Key('gameSessionQuitDialog')), findsNothing);

    await tester.tap(find.byKey(const Key('choice_5')));
    await tester.pumpAndSettle();

    // 1問答えた後にバック操作を行うと、終了確認ダイアログが出る。
    // (pt_BRロケールではBackButtonのツールチップがローカライズされ、
    // tooltip('Back')を前提とするtester.pageBack()が使えないため、
    // 他のテストと同様にfind.byType(BackButton)でタップする)。
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gameSessionQuitDialog')), findsOneWidget);

    // 「続ける」を選ぶと画面に留まる。
    await tester.tap(find.byKey(const Key('gameSessionQuitContinueButton')));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionScreen), findsOneWidget);

    // もう一度バック操作し、「終了」を選ぶと画面を離れられる。
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gameSessionQuitEndButton')));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionScreen), findsNothing);
  });
}
