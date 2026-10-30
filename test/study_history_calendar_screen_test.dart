import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/in_memory_progress_store.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/study_history_calendar_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

void main() {
  testWidgets('学習した日がカレンダーに反映され、月送りができる', (tester) async {
    final clock = FixedClock(DateTime(2026, 10, 15));
    final progressStore = InMemoryProgressStore();
    await progressStore.recordAttempt(
      Attempt(
        questionId: 'q1',
        unitId: 'mat_numeros_1',
        correct: true,
        answeredAt: DateTime(2026, 10, 5, 9),
      ),
    );
    await progressStore.recordAttempt(
      Attempt(
        questionId: 'q2',
        unitId: 'mat_numeros_1',
        correct: false,
        answeredAt: DateTime(2026, 10, 10, 20),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: StudyHistoryCalendarScreen(
          unitIds: const ['mat_numeros_1'],
          progressStore: progressStore,
          clock: clock,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 学習した2日分(10/5, 10/10)がそれぞれ強調表示される。
    expect(
      find.byKey(Key('studyCalendarStudiedDay_${DateTime(2026, 10, 5).toIso8601String()}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('studyCalendarStudiedDay_${DateTime(2026, 10, 10).toIso8601String()}')),
      findsOneWidget,
    );
    // 学習していない日は強調表示されない。
    expect(
      find.byKey(Key('studyCalendarStudiedDay_${DateTime(2026, 10, 6).toIso8601String()}')),
      findsNothing,
    );

    // 翌月に送ると、今月分の強調表示は消える。
    await tester.tap(find.byKey(const Key('studyCalendarNextMonthButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('studyCalendarStudiedDay_${DateTime(2026, 10, 5).toIso8601String()}')),
      findsNothing,
    );

    // 前月に戻れば再び表示される。
    await tester.tap(find.byKey(const Key('studyCalendarPrevMonthButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('studyCalendarStudiedDay_${DateTime(2026, 10, 5).toIso8601String()}')),
      findsOneWidget,
    );
  });
}
