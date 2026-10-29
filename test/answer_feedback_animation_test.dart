import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/answer_feedback_animation.dart';

void main() {
  testWidgets('正解時は星の演出つきで子ウィジェットが表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnswerFeedbackAnimation(
            correct: true,
            child: Text('Correto!'),
          ),
        ),
      ),
    );

    expect(find.text('Correto!'), findsOneWidget);
    expect(find.byKey(const Key('answerCelebrationStar')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Correto!'), findsOneWidget);
  });

  testWidgets('不正解時は星の演出なしで子ウィジェットが表示される', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnswerFeedbackAnimation(
            correct: false,
            child: Text('Incorreto'),
          ),
        ),
      ),
    );

    expect(find.text('Incorreto'), findsOneWidget);
    expect(find.byKey(const Key('answerCelebrationStar')), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Incorreto'), findsOneWidget);
  });
}
