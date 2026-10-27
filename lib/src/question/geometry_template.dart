/// BNCC Geometria向けの図形問題テンプレ。図形名の表示はarbキー経由（直書き禁止）。
class ShapeTemplate {
  const ShapeTemplate({
    required this.id,
    required this.shapeNameKey,
    required this.sides,
    this.explanationId = '',
  }) : assert(sides >= 1);

  factory ShapeTemplate.fromJson(Map<String, dynamic> j) => ShapeTemplate(
        id: j['id'] as String,
        shapeNameKey: j['shapeNameKey'] as String,
        sides: j['sides'] as int,
        explanationId: (j['explanationId'] as String?) ?? '',
      );

  final String id;
  final String shapeNameKey;
  final int sides;
  final String explanationId;
}
