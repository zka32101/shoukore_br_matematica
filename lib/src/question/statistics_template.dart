enum DataSetOperation { max, min, mode }

DataSetOperation _operationFromJson(String v) {
  switch (v) {
    case 'max':
      return DataSetOperation.max;
    case 'min':
      return DataSetOperation.min;
    case 'mode':
      return DataSetOperation.mode;
    default:
      throw ArgumentError('unknown operation: $v');
  }
}

/// BNCC Probabilidade e estatística向けのデータ読み取り問題テンプレ。
class DataSetTemplate {
  const DataSetTemplate({
    required this.id,
    required this.operation,
    required this.valueCount,
    required this.minValue,
    required this.maxValue,
    this.explanationId = '',
  })  : assert(valueCount >= 2),
        assert(minValue <= maxValue);

  factory DataSetTemplate.fromJson(Map<String, dynamic> j) => DataSetTemplate(
        id: j['id'] as String,
        operation: _operationFromJson(j['operation'] as String),
        valueCount: j['valueCount'] as int,
        minValue: j['minValue'] as int,
        maxValue: j['maxValue'] as int,
        explanationId: (j['explanationId'] as String?) ?? '',
      );

  final String id;
  final DataSetOperation operation;
  final int valueCount;
  final int minValue;
  final int maxValue;
  final String explanationId;
}
