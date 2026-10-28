enum ArithmeticOperator { add, subtract, multiply, divide }

ArithmeticOperator _operatorFromJson(String v) {
  switch (v) {
    case 'add':
      return ArithmeticOperator.add;
    case 'subtract':
      return ArithmeticOperator.subtract;
    case 'multiply':
      return ArithmeticOperator.multiply;
    case 'divide':
      return ArithmeticOperator.divide;
    default:
      throw ArgumentError('unknown operator: $v');
  }
}

/// 四則演算の問題テンプレ。オペランドの範囲とタイプを定義する。
/// 文章題の題材（登場人物・通貨など）は arb/地域設定側の責務とし、ここでは数式のみ扱う。
/// [wordProblemId]が設定されている場合、アプリ側(`word_problem_resolver.dart`)が
/// その題材で文章題を組み立てる。空の場合は記号のみの数式として表示する。
class ArithmeticTemplate {
  const ArithmeticTemplate({
    required this.id,
    required this.operator,
    required this.minOperand,
    required this.maxOperand,
    this.explanationId = '',
    this.wordProblemId = '',
  }) : assert(minOperand <= maxOperand);

  factory ArithmeticTemplate.fromJson(Map<String, dynamic> j) => ArithmeticTemplate(
        id: j['id'] as String,
        operator: _operatorFromJson(j['operator'] as String),
        minOperand: j['minOperand'] as int,
        maxOperand: j['maxOperand'] as int,
        explanationId: (j['explanationId'] as String?) ?? '',
        wordProblemId: (j['wordProblemId'] as String?) ?? '',
      );

  final String id;
  final ArithmeticOperator operator;
  final int minOperand;
  final int maxOperand;
  final String explanationId;
  final String wordProblemId;
}
