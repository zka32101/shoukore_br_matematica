import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/badge_collection_screen.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

void main() {
  const units = [
    Unit(
      id: 'mat_numeros_1',
      subjectId: 'matematica',
      grade: 1,
      titleKey: 'unit_numeros_1',
      templateIds: ['tpl_1'],
    ),
  ];

  testWidgets('マスター済みの単元には対応ストランドのバッジ画像が表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: const BadgeCollectionScreen(
          units: units,
          masteredUnitIds: {'mat_numeros_1'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('badgeCard_mat_numeros_1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('badgeCard_mat_numeros_1')),
        matching: find.byWidgetPredicate(
          (w) => w is Image && (w.image as AssetImage).assetName.contains('badge_mastery_numbers'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('達成バッジセクションが表示され、条件を満たすと解除状態になる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: const BadgeCollectionScreen(
          units: units,
          masteredUnitIds: {},
          currentStreakDays: 7,
          totalCorrectAnswers: 120,
          ownedCharacterCount: 6,
          totalCharacterCount: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('achievementSectionTitle')), findsOneWidget);
    expect(find.byKey(const Key('achievementCard_streakDays7')), findsOneWidget);
    expect(find.byKey(const Key('achievementCard_streakDays30')), findsOneWidget);
    expect(find.byKey(const Key('achievementCard_correctAnswers100')), findsOneWidget);
    expect(find.byKey(const Key('achievementCard_collection50')), findsOneWidget);
  });
}
