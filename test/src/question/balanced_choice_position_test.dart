import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/src/question/arithmetic_question_source.dart';
import 'package:shoukore_br_matematica/src/question/arithmetic_template.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

/// 各QuestionSourceの選択肢生成が、短い区間でも正解の位置を偏らせないこと
/// (BalancedChoicePositionSequencerの導入)を確認する。実装の詳細
/// (内部でどのクラスを使うか)ではなく、観測可能な振る舞い(生成される
/// Question.choicesの中で正解がどの位置に来るか)だけを検証する。
void main() {
  test('算数(四則演算)で連続生成した問題は、正解の位置が極端に偏らない', () async {
    final unit = Unit(
      id: 'mat_numeros_1',
      subjectId: 'matematica',
      grade: 1,
      titleKey: 'unit_numeros_1',
      templateIds: const ['tpl_add_1'],
    );
    final template = ArithmeticTemplate(
      id: 'tpl_add_1',
      operator: ArithmeticOperator.add,
      minOperand: 1,
      maxOperand: 9,
      explanationId: 'explanation_add',
    );
    final source = ArithmeticQuestionSource(
      unitsByLocale: {'pt_BR': [unit]},
      templates: {'tpl_add_1': template},
      random: Random(123),
    );

    final positions = <int>[];
    for (var i = 0; i < 40; i++) {
      final question = await source.generate(unitId: unit.id, targetDifficulty: 0.5);
      positions.add(question.choices.indexOf(question.answer));
    }

    // 4択なので、40問中どの位置も極端に(例えば0回や30回超)偏らないはず。
    final counts = <int, int>{};
    for (final p in positions) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    expect(counts.keys.length, greaterThan(1));
    for (final count in counts.values) {
      expect(count, greaterThan(0));
      expect(count, lessThan(30));
    }
  });
}
