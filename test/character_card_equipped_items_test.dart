import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/character_card.dart';
import 'package:shoukore_br_matematica/character_definition.dart';
import 'package:shoukore_br_matematica/equipped_items.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';

void main() {
  final definition = characterDefinitions.first;

  testWidgets('装着中の帽子アイテムがキャラカードにアイコンとして表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: CharacterCard(
          definition: definition,
          level: 1,
          equippedItems: const EquippedItems(hatItemId: 'hat_calculator'),
        ),
      ),
    );

    expect(find.byKey(const Key('characterHatIcon')), findsOneWidget);
  });

  testWidgets('装着中の枠アイテムがキャラカードに枠線として表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: CharacterCard(
          definition: definition,
          level: 1,
          equippedItems: const EquippedItems(frameItemId: 'frame_gold'),
        ),
      ),
    );

    expect(find.byKey(const Key('characterFrameBorder')), findsOneWidget);
  });

  testWidgets('未所持キャラにはアイテムを反映しない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: CharacterCard(
          definition: definition,
          level: 0,
          equippedItems: const EquippedItems(
            hatItemId: 'hat_calculator',
            frameItemId: 'frame_gold',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('characterHatIcon')), findsNothing);
    expect(find.byKey(const Key('characterFrameBorder')), findsNothing);
  });

  testWidgets('アイテム未装着時は何も表示しない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: CharacterCard(definition: definition, level: 1),
      ),
    );

    expect(find.byKey(const Key('characterHatIcon')), findsNothing);
    expect(find.byKey(const Key('characterFrameBorder')), findsNothing);
  });
}
