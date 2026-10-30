import 'l10n/app_localizations.dart';

/// 「学ぶ」画面(LessonScreen)で表示する、1単元分の教科書的な解説コンテンツ。
/// 問題を解く前に読む想定で、既存の一言解説(explanation_resolver.dart、
/// 不正解時のヒント用)とは別物。CLAUDE.md共通要件「教科書より分かりやすい
/// 丁寧な解説」に対応する。
class WorkedExample {
  const WorkedExample({
    required this.question,
    required this.answer,
    required this.explanation,
  });

  final String question;
  final String answer;
  final String explanation;
}

class Lesson {
  const Lesson({required this.intro, required this.tip, required this.example});

  final String intro;
  final String tip;
  final WorkedExample example;
}

/// 単元IDからレッスンを引く。まだレッスンを用意していない単元は`null`を
/// 返す(呼び出し側で「学ぶ」ボタン自体を出さない判断に使う)。
Lesson? resolveLesson(AppLocalizations l10n, String unitId) {
  switch (unitId) {
    case 'mat_numeros_1':
      return Lesson(
        intro: l10n.lessonMatNumeros1Intro,
        tip: l10n.lessonMatNumeros1Tip,
        example: WorkedExample(
          question: l10n.lessonMatNumeros1ExampleQuestion,
          answer: l10n.lessonMatNumeros1ExampleAnswer,
          explanation: l10n.lessonMatNumeros1ExampleExplanation,
        ),
      );
    case 'mat_algebra_1':
      return Lesson(
        intro: l10n.lessonMatAlgebra1Intro,
        tip: l10n.lessonMatAlgebra1Tip,
        example: WorkedExample(
          question: l10n.lessonMatAlgebra1ExampleQuestion,
          answer: l10n.lessonMatAlgebra1ExampleAnswer,
          explanation: l10n.lessonMatAlgebra1ExampleExplanation,
        ),
      );
    case 'mat_geometria_1':
      return Lesson(
        intro: l10n.lessonMatGeometria1Intro,
        tip: l10n.lessonMatGeometria1Tip,
        example: WorkedExample(
          question: l10n.lessonMatGeometria1ExampleQuestion,
          answer: l10n.lessonMatGeometria1ExampleAnswer,
          explanation: l10n.lessonMatGeometria1ExampleExplanation,
        ),
      );
    case 'mat_grandezas_1':
      return Lesson(
        intro: l10n.lessonMatGrandezas1Intro,
        tip: l10n.lessonMatGrandezas1Tip,
        example: WorkedExample(
          question: l10n.lessonMatGrandezas1ExampleQuestion,
          answer: l10n.lessonMatGrandezas1ExampleAnswer,
          explanation: l10n.lessonMatGrandezas1ExampleExplanation,
        ),
      );
    case 'mat_probabilidade_1':
      return Lesson(
        intro: l10n.lessonMatProbabilidade1Intro,
        tip: l10n.lessonMatProbabilidade1Tip,
        example: WorkedExample(
          question: l10n.lessonMatProbabilidade1ExampleQuestion,
          answer: l10n.lessonMatProbabilidade1ExampleAnswer,
          explanation: l10n.lessonMatProbabilidade1ExampleExplanation,
        ),
      );
    default:
      return null;
  }
}
