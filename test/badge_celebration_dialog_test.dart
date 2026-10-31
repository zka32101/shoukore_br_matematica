import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/badge_celebration_dialog.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';

void main() {
  testWidgets('複数のバッジ獲得が1件ずつ順番にダイアログ表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('showBadgeCelebrationsButton'),
                onPressed: () => showBadgeCelebrations(context, const [
                  BadgeCelebration(unitLabel: 'Números: somar até 10', strandId: 'numbers'),
                  BadgeCelebration(unitLabel: 'Álgebra: sequências até 5', strandId: 'algebra'),
                ]),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('showBadgeCelebrationsButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('badgeCelebrationDialog')), findsOneWidget);
    expect(find.text('Números: somar até 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('badgeCelebrationContinueButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('badgeCelebrationDialog')), findsOneWidget);
    expect(find.text('Álgebra: sequências até 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('badgeCelebrationContinueButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('badgeCelebrationDialog')), findsNothing);
  });
}
