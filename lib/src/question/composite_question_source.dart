import 'package:shoukore_core_global/shoukore_core_global.dart';

/// BNCCの5つのeixo（学習軸）それぞれに対応するQuestionSourceへディスパッチする
/// 合成実装。単元ID（例: `mat_numeros_1`）に含まれる文字列でeixoを判定する。
class CompositeQuestionSource implements QuestionSource {
  CompositeQuestionSource({
    required this.arithmeticSource,
    required this.geometrySource,
    required this.measurementSource,
    required this.sequenceSource,
    required this.statisticsSource,
  });

  final QuestionSource arithmeticSource;
  final QuestionSource geometrySource;
  final QuestionSource measurementSource;
  final QuestionSource sequenceSource;
  final QuestionSource statisticsSource;

  QuestionSource _sourceForUnit(String unitId) {
    if (unitId.contains('geometria')) return geometrySource;
    if (unitId.contains('grandezas')) return measurementSource;
    if (unitId.contains('algebra')) return sequenceSource;
    if (unitId.contains('probabilidade')) return statisticsSource;
    return arithmeticSource;
  }

  @override
  Future<List<Unit>> loadUnits(String locale) => arithmeticSource.loadUnits(locale);

  @override
  Future<Question> generate({
    required String unitId,
    required double targetDifficulty,
  }) {
    return _sourceForUnit(unitId).generate(unitId: unitId, targetDifficulty: targetDifficulty);
  }

  @override
  bool checkAnswer(Question question, String chosenId) =>
      _sourceForUnit(question.unitId).checkAnswer(question, chosenId);
}
