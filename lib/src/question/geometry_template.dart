/// 問うのが辺の数か、対角線の本数か。
enum ShapeQuestionKind { sides, diagonals }

/// BNCC Geometria向けの図形問題テンプレ。図形名の表示はarbキー経由（直書き禁止）。
class ShapeTemplate {
  const ShapeTemplate({
    required this.id,
    required this.shapeNameKey,
    required this.sides,
    this.explanationId = '',
    this.questionKind = ShapeQuestionKind.sides,
  }) : assert(sides >= 1);

  factory ShapeTemplate.fromJson(Map<String, dynamic> j) => ShapeTemplate(
        id: j['id'] as String,
        shapeNameKey: j['shapeNameKey'] as String,
        sides: j['sides'] as int,
        explanationId: (j['explanationId'] as String?) ?? '',
        questionKind: (j['questionKind'] as String?) == 'diagonals'
            ? ShapeQuestionKind.diagonals
            : ShapeQuestionKind.sides,
      );

  final String id;
  final String shapeNameKey;
  final int sides;
  final String explanationId;
  final ShapeQuestionKind questionKind;

  /// 対角線の本数（n角形: n(n-3)/2）。
  int get diagonalCount => sides * (sides - 3) ~/ 2;
}
