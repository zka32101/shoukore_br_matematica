import 'dart:math';

import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'geometry_template.dart';


/// BNCC Geometria向けの既定実装。図形の辺の数を答える問題を生成する。
class GeometryQuestionSource implements QuestionSource {
  GeometryQuestionSource({
    required Map<String, List<Unit>> unitsByLocale,
    required Map<String, ShapeTemplate> templates,
    Random? random,
  })  : _unitsByLocale = unitsByLocale,
        _templates = templates,
        _random = random ?? Random();

  final Map<String, List<Unit>> _unitsByLocale;
  final Map<String, ShapeTemplate> _templates;
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

  ShapeTemplate _pickTemplate(Unit unit) {
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

  @override
  Future<Question> generate({
    required String unitId,
    required double targetDifficulty,
  }) async {
    final unit = _findUnit(unitId);
    final template = _pickTemplate(unit);
    final answer = template.questionKind == ShapeQuestionKind.diagonals
        ? template.diagonalCount
        : template.sides;

    final choices = <int>{answer};
    final offsets = [1, -1, 2, -2];
    var i = 0;
    while (choices.length < 4 && i < offsets.length) {
      final candidate = answer + offsets[i];
      if (candidate >= 1) choices.add(candidate);
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
        'shapeNameKey': template.shapeNameKey,
        'questionKind': template.questionKind.name,
        'sides': template.sides.toString(),
        if (template.scenarioId.isNotEmpty) 'scenarioId': template.scenarioId,
      },
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}
