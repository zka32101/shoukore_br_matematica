import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/lesson_content.dart';
import 'package:shoukore_br_matematica/lesson_screen.dart';

void main() {
  Future<AppLocalizations> loadL10n(WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );
    return l10n;
  }

  testWidgets('導入・ヒントは最初から見え、答えと解説は段階的に開く', (tester) async {
    final l10n = await loadL10n(tester);
    final lesson = resolveLesson(l10n, 'mat_numeros_1')!;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: LessonScreen(unitId: 'mat_numeros_1', lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lessonIntroText')), findsOneWidget);
    expect(find.byKey(const Key('lessonTipText')), findsOneWidget);
    expect(find.byKey(const Key('lessonExampleAnswerText')), findsNothing);

    await tester.tap(find.byKey(const Key('lessonRevealAnswerButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonExampleAnswerText')), findsOneWidget);
    expect(find.byKey(const Key('lessonExampleExplanationText')), findsNothing);

    await tester.tap(find.byKey(const Key('lessonRevealExplanationButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessonExampleExplanationText')), findsOneWidget);
  });

  testWidgets('まだレッスンを用意していない単元はnullを返す', (tester) async {
    final l10n = await loadL10n(tester);
    expect(resolveLesson(l10n, 'mat_numeros_2'), isNull);
  });
}
