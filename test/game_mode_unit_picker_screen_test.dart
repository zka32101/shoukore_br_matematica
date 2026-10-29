import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/game_mode_unit_picker_screen.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

void main() {
  const units = [
    Unit(
      id: 'mat_numeros_1',
      subjectId: 'matematica',
      grade: 1,
      titleKey: 'unit_mat_numeros_1',
      templateIds: ['tpl_add_1_10'],
    ),
    Unit(
      id: 'mat_numeros_2',
      subjectId: 'matematica',
      grade: 2,
      titleKey: 'unit_mat_numeros_2',
      templateIds: ['tpl_add_1_100'],
    ),
  ];

  testWidgets('ロック中の単元は鍵アイコン、マスター済みの単元はトロフィーバッジが表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: GameModeUnitPickerScreen(
          units: units,
          onUnitTap: (_, __) async {},
          lockedUnitIds: const {'mat_numeros_2'},
          masteredUnitIds: const {'mat_numeros_1'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gameModeUnitMasteredBadge_mat_numeros_1')), findsOneWidget);
    expect(find.byKey(const Key('gameModeUnitMasteredBadge_mat_numeros_2')), findsNothing);

    // ゲーム専用の進捗(1/2単元をマスター)が表示される。
    expect(find.text('1 de 2 unidades dominadas jogando'), findsOneWidget);

    final lockedTile = tester.widget<ListTile>(
      find.byKey(const Key('gameModeUnitOption_mat_numeros_2')),
    );
    expect((lockedTile.leading as Icon).icon, Icons.lock_outline);

    final unlockedTile = tester.widget<ListTile>(
      find.byKey(const Key('gameModeUnitOption_mat_numeros_1')),
    );
    expect((unlockedTile.leading as Icon).icon, Icons.sports_esports_outlined);
  });
}
