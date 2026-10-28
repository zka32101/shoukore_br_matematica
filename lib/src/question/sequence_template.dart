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
    this.multiplier = 0,
    this.scenarioId = '',
  })  : assert(startMin <= startMax),
        assert(stepMin <= stepMax),
        assert(length >= 2),
        assert(multiplier == 0 || multiplier >= 2);

  factory SequencePatternTemplate.fromJson(Map<String, dynamic> j) => SequencePatternTemplate(
        id: j['id'] as String,
        startMin: j['startMin'] as int,
        startMax: j['startMax'] as int,
        stepMin: j['stepMin'] as int,
        stepMax: j['stepMax'] as int,
        length: (j['length'] as int?) ?? 4,
        explanationId: (j['explanationId'] as String?) ?? '',
        descending: (j['descending'] as bool?) ?? false,
        multiplier: (j['multiplier'] as int?) ?? 0,
        scenarioId: (j['scenarioId'] as String?) ?? '',
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

  /// 2以上の場合、等差数列ではなく倍数パターン（例: ×2, ×3）の数列として
  /// 生成する（`stepMin`/`stepMax`は無視される）。既定の0は等差数列。
  final int multiplier;

  /// 設定時、応用シナリオ(学校・実生活の場面)の出題文で表示する
  /// (アプリ側question_prompt_resolver.dartが解決)。空なら汎用の出題文。
  final String scenarioId;
}
