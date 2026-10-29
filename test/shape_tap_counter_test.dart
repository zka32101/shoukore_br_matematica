import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/shape_tap_counter.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: Scaffold(body: child),
      );

  testWidgets('辺の数だけマーカーが表示され、タップすると数が増える', (tester) async {
    await tester.pumpWidget(wrap(const ShapeTapCounter(sides: 4)));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      expect(find.byKey(Key('shapeEdgeMarker_$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('shapeEdgeMarker_4')), findsNothing);
    expect(find.text('Você contou 0 lado(s)! Toque em cada ponto da figura.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shapeEdgeMarker_0')));
    await tester.pumpAndSettle();
    expect(find.text('Você contou 1 lado(s)! Toque em cada ponto da figura.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shapeEdgeMarker_1')));
    await tester.pumpAndSettle();
    expect(find.text('Você contou 2 lado(s)! Toque em cada ponto da figura.'), findsOneWidget);

    // もう一度タップすると数え直せる(取り消し)。
    await tester.tap(find.byKey(const Key('shapeEdgeMarker_0')));
    await tester.pumpAndSettle();
    expect(find.text('Você contou 1 lado(s)! Toque em cada ponto da figura.'), findsOneWidget);
  });
}
