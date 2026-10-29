import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/character_definition.dart';
import 'package:shoukore_br_matematica/character_growth_celebration_dialog.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';

void main() {
  final character = characterDefinitions.first;

  testWidgets('新規所持・レベルアップが1体ずつ順番にダイアログ表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('showCelebrationsButton'),
                onPressed: () => showCharacterGrowthCelebrations(context, [
                  CharacterGrowthCelebration(
                    character: character,
                    level: 1,
                    newlyOwned: true,
                  ),
                  CharacterGrowthCelebration(
                    character: character,
                    level: 2,
                    newlyOwned: false,
                  ),
                ]),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('showCelebrationsButton')));
    await tester.pumpAndSettle();

    // 1体目: 新規所持の演出。
    expect(find.byKey(const Key('characterGrowthCelebrationDialog')), findsOneWidget);
    expect(find.text('Novo amigo!'), findsOneWidget);
    expect(find.byKey(const Key('characterGrowthCelebrationName')), findsOneWidget);

    await tester.tap(find.byKey(const Key('characterGrowthCelebrationContinueButton')));
    await tester.pumpAndSettle();

    // 2体目(実際は同じキャラの別レベル): レベルアップの演出に切り替わる。
    expect(find.byKey(const Key('characterGrowthCelebrationDialog')), findsOneWidget);
    expect(find.text('Evoluiu!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('characterGrowthCelebrationContinueButton')));
    await tester.pumpAndSettle();

    // すべて閉じると、もうダイアログは残らない。
    expect(find.byKey(const Key('characterGrowthCelebrationDialog')), findsNothing);
  });
}
