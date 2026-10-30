import 'dart:math';

import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'measurement_template.dart';


/// BNCC Grandezas e medidas向けの既定実装。単位変換問題（例: cm→m）を生成する。
class MeasurementQuestionSource implements QuestionSource {
  MeasurementQuestionSource({
    required Map<String, List<Unit>> unitsByLocale,
    required Map<String, UnitConversionTemplate> templates,
    Random? random,
  })  : _unitsByLocale = unitsByLocale,
        _templates = templates,
        _random = random ?? Random() {
    _choicePositionSequencer = BalancedChoicePositionSequencer(random: _random);
  }

  final Map<String, List<Unit>> _unitsByLocale;
  final Map<String, UnitConversionTemplate> _templates;
  final Random _random;
  int _sequence = 0;

  /// 正解の選択肢の位置が短い区間でも偏らないよう、順序とは別に位置だけを
  /// 均等にする(CLAUDE.md共通要件「選択肢はランダムに」のバランス面)。
  late final BalancedChoicePositionSequencer _choicePositionSequencer;

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

  UnitConversionTemplate _pickTemplate(Unit unit) {
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

    final generated = template.minValue +
        _random.nextInt(template.maxValue - template.minValue + 1);

    // reverse: false（既定）: generatedはtoUnit側の値。fromUnit側の値
    // (displayValue)はfactor倍して見せ、toUnit側の値(generated)を答えさせる。
    // reverse: true: generatedはtoUnit（大きい単位）側の値。それをそのまま
    // 見せ、fromUnit（小さい単位）側の値(= generated * factor)を答えさせる。
    final int answer;
    final int displayValue;
    final String displayUnitKey;
    final String answerUnitKey;
    if (!template.reverse) {
      answer = generated;
      displayValue = generated * template.factor;
      displayUnitKey = template.fromUnitKey;
      answerUnitKey = template.toUnitKey;
    } else {
      answer = generated * template.factor;
      displayValue = generated;
      displayUnitKey = template.toUnitKey;
      answerUnitKey = template.fromUnitKey;
    }

    final choices = <int>{answer};
    final offsets = [1, -1, 2, -2];
    var i = 0;
    while (choices.length < 4 && i < offsets.length) {
      final candidate = answer + offsets[i];
      if (candidate >= 0) choices.add(candidate);
      i++;
    }
    final wrongChoices = choices.where((c) => c != answer).toList()..shuffle(_random);
    final position = _choicePositionSequencer.nextPosition(wrongChoices.length + 1);
    final choiceList = [...wrongChoices]..insert(position, answer);

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
        'value': displayValue.toString(),
        'fromUnitKey': displayUnitKey,
        'toUnitKey': answerUnitKey,
        if (template.scenarioId.isNotEmpty) 'scenarioId': template.scenarioId,
      },
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}
