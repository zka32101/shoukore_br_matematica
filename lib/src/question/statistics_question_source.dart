import 'dart:math';

import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'statistics_template.dart';

/// BNCC Probabilidade e estatística向けの既定実装。データの最大値・最小値・最頻値を
/// 答えさせる問題を生成する。
class StatisticsQuestionSource implements QuestionSource {
  StatisticsQuestionSource({
    required Map<String, List<Unit>> unitsByLocale,
    required Map<String, DataSetTemplate> templates,
    Random? random,
  })  : _unitsByLocale = unitsByLocale,
        _templates = templates,
        _random = random ?? Random();

  final Map<String, List<Unit>> _unitsByLocale;
  final Map<String, DataSetTemplate> _templates;
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

  DataSetTemplate _pickTemplate(Unit unit) {
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

  int _randomInRange(int min, int max) => min + _random.nextInt(max - min + 1);

  (List<int>, int) _buildValuesAndAnswer(DataSetTemplate template) {
    switch (template.operation) {
      case DataSetOperation.max:
      case DataSetOperation.min:
      case DataSetOperation.sum:
      case DataSetOperation.range:
        final values = List<int>.generate(
          template.valueCount,
          (_) => _randomInRange(template.minValue, template.maxValue),
        );
        final answer = switch (template.operation) {
          DataSetOperation.max => values.reduce(max),
          DataSetOperation.min => values.reduce(min),
          DataSetOperation.sum => values.reduce((a, b) => a + b),
          DataSetOperation.range => values.reduce(max) - values.reduce(min),
          DataSetOperation.mode => throw StateError('handled in separate branch'),
        };
        return (values, answer);
      case DataSetOperation.mode:
        final modeValue = _randomInRange(template.minValue, template.maxValue);
        final modeCount = (template.valueCount / 2).ceil() + 1;
        final values = List.filled(modeCount, modeValue, growable: true);
        while (values.length < template.valueCount) {
          final other = _randomInRange(template.minValue, template.maxValue);
          if (other == modeValue) continue;
          values.add(other);
        }
        values.shuffle(_random);
        return (values, modeValue);
    }
  }

  @override
  Future<Question> generate({
    required String unitId,
    required double targetDifficulty,
  }) async {
    final unit = _findUnit(unitId);
    final template = _pickTemplate(unit);
    final (values, answer) = _buildValuesAndAnswer(template);

    final choices = <int>{answer};
    final offsets = [1, -1, 2, -2];
    var i = 0;
    while (choices.length < 4 && i < offsets.length) {
      final candidate = answer + offsets[i];
      if (candidate >= template.minValue - 2) choices.add(candidate);
      i++;
    }
    final choiceList = choices.toList()..shuffle(_random);

    _sequence++;
    return Question(
      id: 'q_${unitId}_$_sequence',
      unitId: unitId,
      type: QuestionType.choice,
      difficulty: targetDifficulty.clamp(0, 1),
      choices: choiceList.map((c) => c.toString()).toList(),
      answer: answer.toString(),
      explanationId: template.explanationId,
      params: {
        'values': values.join(','),
        'operation': template.operation.name,
        if (template.scenarioId.isNotEmpty) 'scenarioId': template.scenarioId,
      },
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}
