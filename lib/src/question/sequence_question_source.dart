import 'dart:math';

import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'sequence_template.dart';

/// BNCC Álgebra向けの既定実装。等差数列を提示し、次の項を答えさせる問題を生成する。
class SequenceQuestionSource implements QuestionSource {
  SequenceQuestionSource({
    required Map<String, List<Unit>> unitsByLocale,
    required Map<String, SequencePatternTemplate> templates,
    Random? random,
  })  : _unitsByLocale = unitsByLocale,
        _templates = templates,
        _random = random ?? Random();

  final Map<String, List<Unit>> _unitsByLocale;
  final Map<String, SequencePatternTemplate> _templates;
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

  SequencePatternTemplate _pickTemplate(Unit unit) {
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

    final start = template.startMin + _random.nextInt(template.startMax - template.startMin + 1);
    final stepSpan = template.stepMax - template.stepMin + 1;
    final stepMagnitude = max(template.stepMin + _random.nextInt(stepSpan), 1);
    final step = template.descending ? -stepMagnitude : stepMagnitude;

    final terms = List<int>.generate(template.length, (i) => start + step * i);
    final answer = start + step * template.length;

    final choices = <int>{answer};
    final offsets = [step, -step, step * 2, -step * 2];
    var i = 0;
    while (choices.length < 4 && i < offsets.length) {
      final candidate = answer + offsets[i];
      choices.add(candidate);
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
      params: {'terms': terms.join(',')},
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}
