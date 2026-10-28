/// BNCC Álgebra向けの等差数列パターン問題テンプレ。
class SequencePatternTemplate {
  const SequencePatternTemplate({
    required this.id,
    required this.startMin,
    required this.startMax,
    required this.stepMin,
    required this.stepMax,
    this.length = 4,
    this.explanationId = '',
    this.descending = false,
  })  : assert(startMin <= startMax),
        assert(stepMin <= stepMax),
        assert(length >= 2);

  factory SequencePatternTemplate.fromJson(Map<String, dynamic> j) => SequencePatternTemplate(
        id: j['id'] as String,
        startMin: j['startMin'] as int,
        startMax: j['startMax'] as int,
        stepMin: j['stepMin'] as int,
        stepMax: j['stepMax'] as int,
        length: (j['length'] as int?) ?? 4,
        explanationId: (j['explanationId'] as String?) ?? '',
        descending: (j['descending'] as bool?) ?? false,
      );

  final String id;
  final int startMin;
  final int startMax;

  /// 公差の生成範囲。0を避けるため、生成時に1以上に補正する。
  final int stepMin;
  final int stepMax;

  /// 提示する数列の項数（この次の項を答えさせる）。
  final int length;
  final String explanationId;

  /// `true`の場合、数が減っていく数列（公差を引き算で適用）にする。
  /// `startMin`/`startMax`は数列の最初の項（最大値側）の生成範囲のまま。
  final bool descending;
}
