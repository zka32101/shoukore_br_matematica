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
    this.reverse = false,
    this.scenarioId = '',
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
        reverse: (j['reverse'] as bool?) ?? false,
        scenarioId: (j['scenarioId'] as String?) ?? '',
      );

  final String id;
  final String fromUnitKey;
  final String toUnitKey;

  /// `fromUnit` を `toUnit` に変換する倍率（例: cm→m なら100）。
  final int factor;

  /// `reverse: false`（既定）の場合、toUnit側の値の生成範囲。
  /// `reverse: true`の場合、toUnit（大きい単位）側の値をこの範囲で生成し、
  /// fromUnit（小さい単位）側の値を答えさせる（例: m→cmのように、大きい
  /// 単位から小さい単位への変換を出題する）。
  final int minValue;
  final int maxValue;
  final String explanationId;
  final bool reverse;

  /// 設定時、応用シナリオ(学校・実生活の場面)の出題文で表示する
  /// (アプリ側question_prompt_resolver.dartが解決)。空なら汎用の出題文。
  final String scenarioId;
}
