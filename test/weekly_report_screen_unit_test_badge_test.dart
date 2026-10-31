import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_cache.dart';
import 'package:shoukore_br_matematica/weekly_report_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

void main() {
  testWidgets('まとめテスト合格済みの単元には合格バッジが表示される', (tester) async {
    final clock = FixedClock(DateTime(2026, 10, 30));
    final progressStore = InMemoryProgressStore();
    await progressStore.recordAttempt(
      Attempt(
        questionId: 'q1',
        unitId: 'mat_numeros_1',
        correct: true,
        answeredAt: DateTime(2026, 10, 29),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: WeeklyReportScreen(
          unitIds: const ['mat_numeros_1', 'mat_numeros_2'],
          progressStore: progressStore,
          clock: clock,
          questionCache: QuestionCache(),
          unitTestPassedIds: const {'mat_numeros_1'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weeklyReportUnit_mat_numeros_1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('weeklyReportUnit_mat_numeros_1')),
        matching: find.byKey(const Key('weeklyReportUnitTestPassedIcon')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('単元名は内部IDではなく人が読める名前で表示される', (tester) async {
    final clock = FixedClock(DateTime(2026, 10, 30));
    final progressStore = InMemoryProgressStore();
    await progressStore.recordAttempt(
      Attempt(
        questionId: 'q1',
        unitId: 'mat_numeros_1',
        correct: true,
        answeredAt: DateTime(2026, 10, 29),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: WeeklyReportScreen(
          unitIds: const ['mat_numeros_1'],
          progressStore: progressStore,
          clock: clock,
          questionCache: QuestionCache(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('mat_numeros_1'), findsNothing);
    expect(find.textContaining('Números: somar até 10'), findsOneWidget);
  });
}
