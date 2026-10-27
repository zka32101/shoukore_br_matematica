/// BNCC Grandezas e medidas向けの単位変換問題テンプレ。単位名の表示はarbキー経由。
class UnitConversionTemplate {
  const UnitConversionTemplate({
    required this.id,
    required this.fromUnitKey,
    required this.toUnitKey,
    required this.factor,
    required this.minValue,
    required this.maxValue,
    this.explanationId = '',
  })  : assert(factor > 0),
        assert(minValue <= maxValue);

  factory UnitConversionTemplate.fromJson(Map<String, dynamic> j) => UnitConversionTemplate(
        id: j['id'] as String,
        fromUnitKey: j['fromUnitKey'] as String,
        toUnitKey: j['toUnitKey'] as String,
        factor: j['factor'] as int,
        minValue: j['minValue'] as int,
        maxValue: j['maxValue'] as int,
        explanationId: (j['explanationId'] as String?) ?? '',
      );

  final String id;
  final String fromUnitKey;
  final String toUnitKey;

  /// `fromUnit` を `toUnit` に変換する倍率（例: cm→m なら100）。
  final int factor;

  /// 変換後の値（toUnit側）の生成範囲。
  final int minValue;
  final int maxValue;
  final String explanationId;
}
