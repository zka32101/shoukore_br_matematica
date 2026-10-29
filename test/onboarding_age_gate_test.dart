import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') return null;
    return null;
  });

  testWidgets(
    'オンボーディングの年齢確認(必須)で児童(同意年齢未満)の場合、'
    '保護者同意の質問が必ず表示される',
    (tester) async {
      await tester.pumpWidget(const ShoukoreBrMatematicaApp());
      await tester.pumpAndSettle();

      // オンボーディングの体験向上: 進捗ドットが表示され、最初は1つ目が
      // アクティブ(幅広)になっている。
      expect(find.byKey(const Key('onboardingProgressDots')), findsOneWidget);
      final firstDot = tester.widget<AnimatedContainer>(
        find.byKey(const Key('onboardingProgressDot_0')),
      );
      final secondDot = tester.widget<AnimatedContainer>(
        find.byKey(const Key('onboardingProgressDot_1')),
      );
      expect(firstDot.constraints?.maxWidth, 20);
      expect(secondDot.constraints?.maxWidth, 8);

      await tester.tap(find.byKey(const Key('onboardingWelcomeNextButton')));
      await tester.pumpAndSettle();

      // 年齢確認（必須、スキップボタンは存在しない）。
      expect(find.byKey(const Key('onboardingAgeGateTitle')), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);

      // 2020年生まれ(6歳)はpt_BRの同意年齢(12歳)未満のため、保護者同意の
      // 質問が続けて表示される。
      await tester.enterText(find.byKey(const Key('onboardingBirthYearField')), '2020');
      await tester.tap(find.byKey(const Key('onboardingAgeGateConfirmButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingConsentTitle')), findsOneWidget);
      expect(find.byKey(const Key('onboardingConsentAcceptButton')), findsOneWidget);
      expect(find.byKey(const Key('onboardingConsentDeclineButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboardingConsentAcceptButton')));
      await tester.pumpAndSettle();

      // 同意済みでAhaモーメントに進む。
      expect(find.byKey(const Key('onboardingQuizQuestionText')), findsOneWidget);
    },
  );
}
