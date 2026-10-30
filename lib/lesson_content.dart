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

/// 単元IDからレッスンを引く。問題を持つ全25単元分を用意している
/// (unit_name_resolver.dartと同じ、switch-caseでIDごとに文言を解決する方式)。
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
    case 'mat_numeros_2':
      return Lesson(
        intro: l10n.lessonMatNumeros2Intro,
        tip: l10n.lessonMatNumeros2Tip,
        example: WorkedExample(
          question: l10n.lessonMatNumeros2ExampleQuestion,
          answer: l10n.lessonMatNumeros2ExampleAnswer,
          explanation: l10n.lessonMatNumeros2ExampleExplanation,
        ),
      );
    case 'mat_numeros_3':
      return Lesson(
        intro: l10n.lessonMatNumeros3Intro,
        tip: l10n.lessonMatNumeros3Tip,
        example: WorkedExample(
          question: l10n.lessonMatNumeros3ExampleQuestion,
          answer: l10n.lessonMatNumeros3ExampleAnswer,
          explanation: l10n.lessonMatNumeros3ExampleExplanation,
        ),
      );
    case 'mat_numeros_4':
      return Lesson(
        intro: l10n.lessonMatNumeros4Intro,
        tip: l10n.lessonMatNumeros4Tip,
        example: WorkedExample(
          question: l10n.lessonMatNumeros4ExampleQuestion,
          answer: l10n.lessonMatNumeros4ExampleAnswer,
          explanation: l10n.lessonMatNumeros4ExampleExplanation,
        ),
      );
    case 'mat_numeros_5':
      return Lesson(
        intro: l10n.lessonMatNumeros5Intro,
        tip: l10n.lessonMatNumeros5Tip,
        example: WorkedExample(
          question: l10n.lessonMatNumeros5ExampleQuestion,
          answer: l10n.lessonMatNumeros5ExampleAnswer,
          explanation: l10n.lessonMatNumeros5ExampleExplanation,
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
    case 'mat_algebra_2':
      return Lesson(
        intro: l10n.lessonMatAlgebra2Intro,
        tip: l10n.lessonMatAlgebra2Tip,
        example: WorkedExample(
          question: l10n.lessonMatAlgebra2ExampleQuestion,
          answer: l10n.lessonMatAlgebra2ExampleAnswer,
          explanation: l10n.lessonMatAlgebra2ExampleExplanation,
        ),
      );
    case 'mat_algebra_3':
      return Lesson(
        intro: l10n.lessonMatAlgebra3Intro,
        tip: l10n.lessonMatAlgebra3Tip,
        example: WorkedExample(
          question: l10n.lessonMatAlgebra3ExampleQuestion,
          answer: l10n.lessonMatAlgebra3ExampleAnswer,
          explanation: l10n.lessonMatAlgebra3ExampleExplanation,
        ),
      );
    case 'mat_algebra_4':
      return Lesson(
        intro: l10n.lessonMatAlgebra4Intro,
        tip: l10n.lessonMatAlgebra4Tip,
        example: WorkedExample(
          question: l10n.lessonMatAlgebra4ExampleQuestion,
          answer: l10n.lessonMatAlgebra4ExampleAnswer,
          explanation: l10n.lessonMatAlgebra4ExampleExplanation,
        ),
      );
    case 'mat_algebra_5':
      return Lesson(
        intro: l10n.lessonMatAlgebra5Intro,
        tip: l10n.lessonMatAlgebra5Tip,
        example: WorkedExample(
          question: l10n.lessonMatAlgebra5ExampleQuestion,
          answer: l10n.lessonMatAlgebra5ExampleAnswer,
          explanation: l10n.lessonMatAlgebra5ExampleExplanation,
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
    case 'mat_geometria_2':
      return Lesson(
        intro: l10n.lessonMatGeometria2Intro,
        tip: l10n.lessonMatGeometria2Tip,
        example: WorkedExample(
          question: l10n.lessonMatGeometria2ExampleQuestion,
          answer: l10n.lessonMatGeometria2ExampleAnswer,
          explanation: l10n.lessonMatGeometria2ExampleExplanation,
        ),
      );
    case 'mat_geometria_3':
      return Lesson(
        intro: l10n.lessonMatGeometria3Intro,
        tip: l10n.lessonMatGeometria3Tip,
        example: WorkedExample(
          question: l10n.lessonMatGeometria3ExampleQuestion,
          answer: l10n.lessonMatGeometria3ExampleAnswer,
          explanation: l10n.lessonMatGeometria3ExampleExplanation,
        ),
      );
    case 'mat_geometria_4':
      return Lesson(
        intro: l10n.lessonMatGeometria4Intro,
        tip: l10n.lessonMatGeometria4Tip,
        example: WorkedExample(
          question: l10n.lessonMatGeometria4ExampleQuestion,
          answer: l10n.lessonMatGeometria4ExampleAnswer,
          explanation: l10n.lessonMatGeometria4ExampleExplanation,
        ),
      );
    case 'mat_geometria_5':
      return Lesson(
        intro: l10n.lessonMatGeometria5Intro,
        tip: l10n.lessonMatGeometria5Tip,
        example: WorkedExample(
          question: l10n.lessonMatGeometria5ExampleQuestion,
          answer: l10n.lessonMatGeometria5ExampleAnswer,
          explanation: l10n.lessonMatGeometria5ExampleExplanation,
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
    case 'mat_grandezas_2':
      return Lesson(
        intro: l10n.lessonMatGrandezas2Intro,
        tip: l10n.lessonMatGrandezas2Tip,
        example: WorkedExample(
          question: l10n.lessonMatGrandezas2ExampleQuestion,
          answer: l10n.lessonMatGrandezas2ExampleAnswer,
          explanation: l10n.lessonMatGrandezas2ExampleExplanation,
        ),
      );
    case 'mat_grandezas_3':
      return Lesson(
        intro: l10n.lessonMatGrandezas3Intro,
        tip: l10n.lessonMatGrandezas3Tip,
        example: WorkedExample(
          question: l10n.lessonMatGrandezas3ExampleQuestion,
          answer: l10n.lessonMatGrandezas3ExampleAnswer,
          explanation: l10n.lessonMatGrandezas3ExampleExplanation,
        ),
      );
    case 'mat_grandezas_4':
      return Lesson(
        intro: l10n.lessonMatGrandezas4Intro,
        tip: l10n.lessonMatGrandezas4Tip,
        example: WorkedExample(
          question: l10n.lessonMatGrandezas4ExampleQuestion,
          answer: l10n.lessonMatGrandezas4ExampleAnswer,
          explanation: l10n.lessonMatGrandezas4ExampleExplanation,
        ),
      );
    case 'mat_grandezas_5':
      return Lesson(
        intro: l10n.lessonMatGrandezas5Intro,
        tip: l10n.lessonMatGrandezas5Tip,
        example: WorkedExample(
          question: l10n.lessonMatGrandezas5ExampleQuestion,
          answer: l10n.lessonMatGrandezas5ExampleAnswer,
          explanation: l10n.lessonMatGrandezas5ExampleExplanation,
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
    case 'mat_probabilidade_2':
      return Lesson(
        intro: l10n.lessonMatProbabilidade2Intro,
        tip: l10n.lessonMatProbabilidade2Tip,
        example: WorkedExample(
          question: l10n.lessonMatProbabilidade2ExampleQuestion,
          answer: l10n.lessonMatProbabilidade2ExampleAnswer,
          explanation: l10n.lessonMatProbabilidade2ExampleExplanation,
        ),
      );
    case 'mat_probabilidade_3':
      return Lesson(
        intro: l10n.lessonMatProbabilidade3Intro,
        tip: l10n.lessonMatProbabilidade3Tip,
        example: WorkedExample(
          question: l10n.lessonMatProbabilidade3ExampleQuestion,
          answer: l10n.lessonMatProbabilidade3ExampleAnswer,
          explanation: l10n.lessonMatProbabilidade3ExampleExplanation,
        ),
      );
    case 'mat_probabilidade_4':
      return Lesson(
        intro: l10n.lessonMatProbabilidade4Intro,
        tip: l10n.lessonMatProbabilidade4Tip,
        example: WorkedExample(
          question: l10n.lessonMatProbabilidade4ExampleQuestion,
          answer: l10n.lessonMatProbabilidade4ExampleAnswer,
          explanation: l10n.lessonMatProbabilidade4ExampleExplanation,
        ),
      );
    case 'mat_probabilidade_5':
      return Lesson(
        intro: l10n.lessonMatProbabilidade5Intro,
        tip: l10n.lessonMatProbabilidade5Tip,
        example: WorkedExample(
          question: l10n.lessonMatProbabilidade5ExampleQuestion,
          answer: l10n.lessonMatProbabilidade5ExampleAnswer,
          explanation: l10n.lessonMatProbabilidade5ExampleExplanation,
        ),
      );
    default:
      return null;
  }
}
