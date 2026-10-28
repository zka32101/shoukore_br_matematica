import 'dart:math';

import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'arithmetic_template.dart';


/// BNCC anos iniciais（算数, 1º–5º ano）向けの四則演算問題を生成する既定実装。
/// 単元ツリー・テンプレはロケールごとのカリキュラムJSON（別途ロード済みのもの）を受け取る。
class ArithmeticQuestionSource implements QuestionSource {
  ArithmeticQuestionSource({
    required Map<String, List<Unit>> unitsByLocale,
    required Map<String, ArithmeticTemplate> templates,
    Random? random,
  })  : _unitsByLocale = unitsByLocale,
        _templates = templates,
        _random = random ?? Random();

  final Map<String, List<Unit>> _unitsByLocale;
  final Map<String, ArithmeticTemplate> _templates;
  final Random _random;
  int _sequence = 0;

  @override
  Future<List<Unit>> loadUnits(String locale) async {
    final units = _unitsByLocale[locale];
    if (units == null) {
      throw ArgumentError('no curriculum loaded for locale: $locale');
    }
    return units;
  }

  Unit _findUnit(String unitId) {
    for (final units in _unitsByLocale.values) {
      for (final u in units) {
        if (u.id == unitId) return u;
      }
    }
    throw ArgumentError('unknown unitId: $unitId');
  }

  ArithmeticTemplate _pickTemplate(Unit unit) {
    if (unit.templateIds.isEmpty) {
      throw ArgumentError('unit ${unit.id} has no templateIds');
    }
    final id = unit.templateIds[_random.nextInt(unit.templateIds.length)];
    final template = _templates[id];
    if (template == null) {
      throw ArgumentError('unknown templateId: $id');
    }
    return template;
  }

  int _scaledBound(ArithmeticTemplate t, double targetDifficulty) {
    final span = t.maxOperand - t.minOperand;
    return t.minOperand + (span * targetDifficulty).round();
  }

  @override
  Future<Question> generate({
    required String unitId,
    required double targetDifficulty,
  }) async {
    final unit = _findUnit(unitId);
    final template = _pickTemplate(unit);
    final bound = max(_scaledBound(template, targetDifficulty), template.minOperand + 1);

    int a, b, answer;
    switch (template.operator) {
      case ArithmeticOperator.add:
        a = template.minOperand + _random.nextInt(bound - template.minOperand + 1);
        b = template.minOperand + _random.nextInt(bound - template.minOperand + 1);
        answer = a + b;
      case ArithmeticOperator.subtract:
        a = template.minOperand + _random.nextInt(bound - template.minOperand + 1);
        b = template.minOperand + _random.nextInt(a - template.minOperand + 1);
        answer = a - b;
      case ArithmeticOperator.multiply:
        a = template.minOperand + _random.nextInt(bound - template.minOperand + 1);
        b = template.minOperand + _random.nextInt(bound - template.minOperand + 1);
        answer = a * b;
      case ArithmeticOperator.divide:
        b = max(template.minOperand, 1) + _random.nextInt(max(bound - template.minOperand, 1));
        final q = max(template.minOperand, 1) + _random.nextInt(max(bound - template.minOperand, 1));
        a = b * q;
        answer = q;
    }

    // 典型的な誤解に対応する誤答候補（WeakNotesAnalyzerでの弱点傾向の集計に使う）。
    // 引き算を足し算と取り違える誤り（a + bを計算してしまう）が代表例。
    // （bは常にa以下に生成されるため、b - aは負になり得る選択肢として不適切）
    final misconceptionChoice = switch (template.operator) {
      ArithmeticOperator.subtract when a + b != answer => a + b,
      _ => null,
    };
    const misconceptionTag = 'subtraction_as_addition';

    final choices = _buildChoices(answer, misconceptionChoice: misconceptionChoice);
    _sequence++;
    return Question(
      id: 'q_${unitId}_$_sequence',
      unitId: unitId,
      type: QuestionType.choice,
      difficulty: targetDifficulty.clamp(0, 1),
      choices: choices.map((c) => c.toString()).toList(),
      answer: answer.toString(),
      explanationId: template.explanationId,
      params: {
        'a': a.toString(),
        'b': b.toString(),
        'operator': template.operator.name,
        if (template.wordProblemId.isNotEmpty) 'wordProblemId': template.wordProblemId,
      },
      misconceptionTags: misconceptionChoice != null && choices.contains(misconceptionChoice)
          ? {misconceptionChoice.toString(): misconceptionTag}
          : const {},
    );
  }

  List<int> _buildChoices(int answer, {int? misconceptionChoice}) {
    final set = <int>{answer};
    if (misconceptionChoice != null && misconceptionChoice >= 0) {
      set.add(misconceptionChoice);
    }
    final offsets = [1, -1, 2, -2, 10, -10];
    var i = 0;
    while (set.length < 4 && i < offsets.length) {
      final candidate = answer + offsets[i];
      if (candidate >= 0) set.add(candidate);
      i++;
    }
    final list = set.toList()..shuffle(_random);
    return list;
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}
