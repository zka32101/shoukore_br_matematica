import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/main.dart';

void main() {
  // flutter_testの既定バインディングにはClipboardチャンネルのモックが無く、
  // Clipboard.setDataを呼ぶと応答が返らずハングする。テスト環境専用のモックを登録する。
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') return null;
    return null;
  });
  // 読み上げ機能(flutter_tts)は実機のTTSエンジンに依存するため、
  // テスト環境では何もしないモックに置き換える。
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
    return 1;
  });

  // 1つのtestWidgets内でシナリオを連結し、pumpWidgetを1回だけ呼ぶ。
  // （Flutter test環境では複数のtestWidgetsでpumpWidgetを繰り返すとアセット読み込みの
  //  非同期処理がテスト間で干渉し、2回目以降でpumpAndSettleがハングする既知の問題がある）
  testWidgets(
    'shoukore_br_matematica 結合確認: 出題採点・保護者ゲート・レポート',
    (tester) async {
      // 選択肢カードがJP版同様に縦に並ぶ大きな丸みカードになり、出題画面の
      // 縦幅が大きく伸びた。既定のテストビューポートのままだと、Sliverの
      // 遅延レイアウト(CLAUDE.md記載の既知の罠)でスクロール位置によって
      // 要素が見つからなくなることがあるため、ビューポート自体を縦に
      // 広げて実質スクロール不要な状態で検証する。
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ShoukoreBrMatematicaApp());
      await tester.pumpAndSettle();

      // 初回起動時はオンボーディング（ウェルカム→年齢確認(必須)→
      // Ahaモーメント→ペイウォール）が表示され、完了するとホーム画面に
      // 遷移する。
      await tester.tap(find.byKey(const Key('onboardingWelcomeNextButton')));
      await tester.pumpAndSettle();

      // 年齢確認（必須、スキップ不可）: 大人の生年(1990年)を入れると
      // pt_BRの同意年齢(12歳)以上のため保護者同意ステップは出ずに進む。
      await tester.enterText(find.byKey(const Key('onboardingBirthYearField')), '1990');
      await tester.tap(find.byKey(const Key('onboardingAgeGateConfirmButton')));
      await tester.pumpAndSettle();

      // 回答前は「もう一度」の文言を出さない。不正解を選んだときだけ出す。
      expect(find.byKey(const Key('onboardingQuizFeedbackText')), findsNothing);
      await tester.tap(find.byKey(const Key('onboardingQuizChoice_4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingQuizFeedbackText')), findsOneWidget);

      // Ahaモーメント: 最初の1問は必ず正解できる固定問題（2+3=5）。
      await tester.tap(find.byKey(const Key('onboardingQuizChoice_5')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingQuizFeedbackText')), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboardingQuizContinueButton')));
      await tester.pumpAndSettle();

      // ペイウォール: 無料継続（スキップ）を選んでホームへ。
      // 特典リスト追加で画面が伸びスクロールが必要になる場合があるため、
      // タップ前にensureVisibleでスキップボタンを表示範囲に入れる。
      await tester.ensureVisible(find.byKey(const Key('onboardingSkipButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboardingSkipButton')));
      await tester.pumpAndSettle();

      // 既定ロケール(pt_BR)でpt_BRのカリキュラム単元一覧が表示される。
      expect(find.byKey(const Key('unit_mat_numeros_1')), findsOneWidget);

      // 既定ではpremiumが無効。1º ano(1年生)の単元は無料で開放、2º ano以降はロックされ、
      // タップしても出題画面に遷移しない。
      expect(find.byKey(const Key('lockIcon')), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('unit_mat_numeros_1')),
          matching: find.byKey(const Key('lockIcon')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('unit_mat_numeros_2')),
          matching: find.byKey(const Key('lockIcon')),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('unit_mat_numeros_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unit_mat_numeros_2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('entitlementLockedSnackBar')), findsOneWidget);
      expect(find.byKey(const Key('masteryText')), findsNothing);

      // premiumトグルをONにすると単元ロックが解除される。
      await tester.tap(find.byKey(const Key('premiumToggleButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lockIcon')), findsNothing);

      // 「ゲームで学ぶ」バナー: タップすると単元選択画面に遷移し、単元を選ぶと
      // 体験型インタラクション付きの出題画面が開く。
      await tester.ensureVisible(find.byKey(const Key('gameModeTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gameModeTile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gameModeUnitOption_mat_numeros_1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('gameModeUnitOption_mat_numeros_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('questionPromptText'), skipOffstage: false), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('gameModeTile')));
      await tester.pumpAndSettle();

      // 保護者向けセクションのタイルは設定タブ(下部メニュー)にまとまっている。
      await tester.tap(find.byKey(const Key('bottomNavSettings')));
      await tester.pumpAndSettle();
      // 設定タブのListViewはSliverベースの遅延レイアウトのため、画面外の
      // 項目はfind.byKeyでは見つからない（CLAUDE.md記載の既知の罠）。
      // scrollUntilVisibleで確実にスクロールしてから操作する。
      await tester.scrollUntilVisible(
        find.byKey(const Key('dataPrivacyTile')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('settingsScrollable')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ferramentas para os responsáveis'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bottomNavHome')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('unit_mat_numeros_1')));
      await tester.pumpAndSettle();

      // 単元をタップすると出題され、回答するとprogressのmasteryが更新される。
      await tester.tap(find.byKey(const Key('unit_mat_numeros_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('masteryText')), findsOneWidget);
      expect(find.text('Domínio: 0%'), findsOneWidget);

      // 読み上げ機能: 問題文を読み上げるボタンが表示される
      // (実際のタップ動作はtest/tts_service_test.dartで確認する)。
      expect(find.byKey(const Key('listenPromptButton')), findsOneWidget);

      // 文章題の出題文が長くなることがあり、小さいテストビューポートでは
      // 選択肢ボタンが画面外に出てタップが当たらないことがあるため、
      // ensureVisibleで確実にスクロールしてから操作する。
      final choiceButtons = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key as ValueKey<String>).value.startsWith('choice_'),
        skipOffstage: false,
      );
      expect(choiceButtons, findsWidgets);
      await tester.ensureVisible(choiceButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(choiceButtons.first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feedbackText'), skipOffstage: false), findsOneWidget);

      // 問題文(prompt)の表示や解説文の充実化で出題画面の縦幅が伸び、ListViewの
      // Sliverが遅延レイアウトする範囲外（offstage）になりがちなため、
      // ビューポート上の可視性に依存しないようskipOffstage:falseで検証する。
      expect(
        find.byKey(const Key('explanationText'), skipOffstage: false),
        findsOneWidget,
      );

      // 読み上げ機能: 解説文を読み上げるボタンが表示される
      // (ListViewのSliver遅延レイアウトでoffstageになりタップ位置が
      // 不安定になることがあるため、タップ動作はTtsServiceの単体テストで
      // 確認する)。
      expect(
        find.byKey(const Key('listenExplanationButton'), skipOffstage: false),
        findsOneWidget,
      );

      // 出題画面にgrowth状態（stage/coins/mission進捗）が表示される。
      // 閾値(10問)に満たないため、正誤に関わらずstageはeggのまま。
      // ドラッグ&ドロップの回答エリア追加で縦幅が伸び、offstageになり得るため
      // skipOffstage:falseで検証する。
      expect(
        find.byKey(const Key('growthStatusText'), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.textContaining('Fase: Ovo', skipOffstage: false), findsOneWidget);

      // 学習ストリーク: 1問回答した時点で1日目のストリークになる。
      expect(find.textContaining('Sequência: 1 dia', skipOffstage: false), findsOneWidget);

      // ホームに戻って週次レポートを開くと、直前の回答が集計に反映されている。
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // ホームにもgrowth状態タイルが表示され、出題画面と状態を共有している。
      await tester.ensureVisible(find.byKey(const Key('growthStatusTile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('growthStatusTile')), findsOneWidget);

      // ウィークリーチャレンジ(今週あと何問正解すれば達成できるか)が
      // ホームに表示される。正誤に関わらずタイル自体は常に表示される。
      await tester.ensureVisible(find.byKey(const Key('weeklyChallengeTile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('weeklyChallengeProgressText')), findsOneWidget);

      // 下部メニューのコレクションタブから、12体一覧画面に切り替えられる。
      // （以前はホーム画面内のタイルからプッシュ遷移だったが、JP版と同様の
      // 常設下部タブに変更した）
      await tester.tap(find.byKey(const Key('bottomNavCollection')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('collectionProgressText')), findsOneWidget);
      expect(find.byKey(const Key('characterCard_tucaninho')), findsOneWidget);
      expect(find.byKey(const Key('characterCard_araruna')), findsOneWidget);

      // 下部メニューのショップタブにも切り替えられる。
      await tester.tap(find.byKey(const Key('bottomNavShop')));
      await tester.pumpAndSettle();
      expect(find.text('Loja'), findsWidgets);

      // 下部メニューのバッジタブから、単元マスター状況の一覧が見られる。
      // 無限出題でも「マスターした」ことが分かるようにするための画面。
      await tester.tap(find.byKey(const Key('bottomNavBadges')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('badgeProgressText')), findsOneWidget);
      expect(find.byKey(const Key('badgeCard_mat_numeros_1')), findsOneWidget);

      // ホームタブに戻る。
      await tester.tap(find.byKey(const Key('bottomNavHome')));
      await tester.pumpAndSettle();

      // ホームの算数ガイドタイルから、分野別の解き方ガイド画面に遷移できる。
      // 既存の解説文言(explanationId)を一覧にして振り返れるようにした画面。
      await tester.ensureVisible(find.byKey(const Key('mathGuideTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mathGuideTile')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mathGuideCard_explanation_add'), skipOffstage: false),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // クロスプロモ: シリーズ最初のアプリのため案内先がまだ無く、
      // 「近日公開」のティーザーが表示される(他アプリが追加されたら
      // 自動でアプリ一覧に切り替わる設計)。設定タブ(下部メニュー)にある。
      await tester.tap(find.byKey(const Key('bottomNavSettings')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('crossPromoComingSoonCard'), skipOffstage: false),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('bottomNavHome')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('unit_mat_numeros_1')));
      await tester.pumpAndSettle();

      // Números以外の4つのeixo（Álgebra/Geometria/Grandezas e Medidas/
      // Probabilidade e Estatística）もCompositeQuestionSourceで正しく
      // 出題できることを確認する（専用のQuestionSourceにディスパッチされる）。
      for (final otherUnitId in [
        'mat_algebra_1',
        'mat_geometria_1',
        'mat_grandezas_2',
        'mat_probabilidade_1',
      ]) {
        await tester.ensureVisible(find.byKey(Key('unit_$otherUnitId')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('unit_$otherUnitId')));
        await tester.pumpAndSettle();

        // Álgebra/Geometria/Grandezas/Probabilidadeいずれも、数列・図形名・
        // 単位変換・データの実生活イメージにつながる出題文(questionPromptText)
        // が表示される。
        expect(
          find.byKey(const Key('questionPromptText'), skipOffstage: false),
          findsOneWidget,
        );

        // シナリオ付きの出題文は長くなることがあり、小さいテストビューポートでは
        // 選択肢ボタンが画面外に出てタップが当たらないことがあるため、
        // ensureVisibleで確実にスクロールしてから操作する。
        final otherChoiceButtons = find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith('choice_'),
          skipOffstage: false,
        );
        expect(otherChoiceButtons, findsWidgets);
        await tester.ensureVisible(otherChoiceButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(otherChoiceButtons.first);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('feedbackText'), skipOffstage: false), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('unit_mat_numeros_1')));
        await tester.pumpAndSettle();
      }

      // 各単元訪問でキャラコレクションのお祝いSnackBarが溜まっている可能性があり、
      // 後続のdataPrivacy画面でのSnackBar検証がキュー待ちの影響を受けて
      // flakyになるため、ここで実時間タイマーを進めて確実に吐き出しておく。
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // 既定(pt_BR)はscreenTimeLimitMinutes:0（無制限）のため、利用時間タイルは
      // 制限なしの状態で表示される。デモ用トグルをONにすると1分制限が模擬される。
      expect(find.byKey(const Key('screenTimeStatusTile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('screenTimeLimitToggleButton')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Restam: 1 min'), findsOneWidget);
      await tester.tap(find.byKey(const Key('screenTimeLimitToggleButton')));
      await tester.pumpAndSettle();

      // 設定タブ(下部メニュー)に切り替える。言語・通知・保護者向けツール
      // など日々の学習導線ではない項目はここにまとめてある。
      await tester.tap(find.byKey(const Key('bottomNavSettings')));
      await tester.pumpAndSettle();

      // 第二言語(英語)への切り替え(CLAUDE.md共通要件)。切り替えた直後に
      // 画面表示が英語に変わることを確認し、以降の検証に影響しないよう
      // すぐにポルトガル語へ戻す。
      await tester.scrollUntilVisible(
        find.byKey(const Key('languageTile')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('settingsScrollable')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('languageTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('languageOption_en')));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Weekly report (for parents)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('languageTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('languageOption_pt')));
      await tester.pumpAndSettle();
      expect(find.text('Idioma'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('weeklyReportTile')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('settingsScrollable')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('weeklyReportTile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weeklyReportAccuracyText')), findsOneWidget);
      expect(find.byKey(const Key('weeklyReportUnit_mat_numeros_1')), findsOneWidget);
      expect(find.byKey(const Key('weeklyReportNoDataText')), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 年齢確認: 2020年生まれ（6歳、pt_BRの同意年齢12歳未満）は保護者同意が必要。
      await tester.scrollUntilVisible(
        find.byKey(const Key('ageVerificationTile')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('settingsScrollable')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consentStatusText')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ageVerificationTile')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('birthYearField')), '2020');
      await tester.tap(find.byKey(const Key('ageGateConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('consentAcceptButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('consentAcceptButton')));
      await tester.pumpAndSettle();

      expect(find.text('Consentimento dos responsáveis: concedido'), findsOneWidget);

      // デイリーミッションのリマインド通知: 既定は未設定、タップで設定/解除を切り替えられる。
      await tester.scrollUntilVisible(
        find.byKey(const Key('dailyReminderTile')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('settingsScrollable')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma notificação agendada'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dailyReminderTile')));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma notificação agendada'), findsNothing);
      await tester.tap(find.byKey(const Key('dailyReminderTile')));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma notificação agendada'), findsOneWidget);

      // 学習データ管理画面: 同意撤回・全データ削除という不可逆な操作に
      // 進めるため、タップすると保護者ゲート(2桁×2桁の乗算)が先に表示される。
      // ダイアログの文言から乱数のa×bを読み取って解答する。
      await tester.scrollUntilVisible(
        find.byKey(const Key('dataPrivacyTile')),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('settingsScrollable')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dataPrivacyTile')));
      await tester.pumpAndSettle();

      final challengeFinder = find.textContaining('Digite o resultado de:');
      expect(challengeFinder, findsOneWidget);
      final challengeText = tester.widget<Text>(challengeFinder).data!;
      final challengeMatch = RegExp(r'(\d+) × (\d+)').firstMatch(challengeText)!;
      final challengeA = int.parse(challengeMatch.group(1)!);
      final challengeB = int.parse(challengeMatch.group(2)!);
      await tester.enterText(find.byType(TextField), '${challengeA * challengeB}');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.text('Consentimento dos responsáveis: concedido'), findsOneWidget);
      // numeros(1件)+他4eixoの結合確認(4件)=5件。
      expect(find.text('Registros de aprendizagem: 5'), findsOneWidget);

      await tester.tap(find.byKey(const Key('copyExportedJsonButton')));
      await tester.pumpAndSettle();
      expect(
        find.text('Conteúdo exportado copiado para a área de transferência'),
        findsOneWidget,
      );
      // SnackBarは実時間のタイマーで自動消去されるため、pumpAndSettleだけでは消えない。
      // 消去を待たないと、画面下部に残った不可視のSnackBarオーバーレイが後続のタップを
      // 吸収してしまう。
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('revokeConsentButton')));
      await tester.pumpAndSettle();
      expect(
        find.text('Consentimento dos responsáveis: não confirmado/não necessário'),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // ホームタブに戻る。
      await tester.tap(find.byKey(const Key('bottomNavHome')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('unit_mat_numeros_1')));
      await tester.pumpAndSettle();

      // 「親も交わって遊びながら学べる機能」(CLAUDE.md共通要件): ホームの
      // ファミリーチャレンジタイルから単元を選び、子ども→保護者の交代で
      // 5問分遊べることを確認する。
      await tester.ensureVisible(find.byKey(const Key('familyChallengeTile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('familyChallengeTile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('familyChallengeUnitOption_mat_numeros_1')));
      await tester.pumpAndSettle();

      for (var round = 0; round < 5; round++) {
        // 子どもの番→保護者の番、1ラウンドにつき2回答する。
        for (var turn = 0; turn < 2; turn++) {
          expect(find.byKey(const Key('familyChallengeTurnChip')), findsOneWidget);
          expect(
            find.byKey(const Key('familyChallengePromptText'), skipOffstage: false),
            findsOneWidget,
          );
          final familyChoiceButtons = find.byKey(
            const Key('familyChallengeNextButton'),
            skipOffstage: false,
          );
          expect(familyChoiceButtons, findsNothing);

          final choiceButton = find.byWidgetPredicate(
            (widget) =>
                widget is ElevatedButton &&
                widget.key is ValueKey<String> &&
                (widget.key as ValueKey<String>).value.startsWith('familyChallengeChoice_'),
          );
          expect(choiceButton, findsWidgets);
          await tester.tap(choiceButton.first);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('familyChallengeFeedbackText')), findsOneWidget);
          await tester.tap(find.byKey(const Key('familyChallengeNextButton')));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byKey(const Key('familyChallengeResultText')), findsOneWidget);
      expect(find.byKey(const Key('familyChallengeResultMessage')), findsOneWidget);
      await tester.tap(find.byKey(const Key('familyChallengeFinishButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('unit_mat_numeros_1')));
      await tester.pumpAndSettle();
    },
  );
}
