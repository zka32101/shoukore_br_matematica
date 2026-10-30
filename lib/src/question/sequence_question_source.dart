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
        _random = random ?? Random() {
    _choicePositionSequencer = BalancedChoicePositionSequencer(random: _random);
  }

  final Map<String, List<Unit>> _unitsByLocale;
  final Map<String, SequencePatternTemplate> _templates;
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

    final start = max(
      template.startMin + _random.nextInt(template.startMax - template.startMin + 1),
      1,
    );

    final List<int> terms;
    final int answer;
    final List<int> offsets;
    if (template.multiplier >= 2) {
      // 倍数パターン（例: 2, 4, 8, 16, ...）。公差ではなく倍率で次の項を求める。
      var term = start;
      terms = List<int>.generate(template.length, (_) {
        final current = term;
        term *= template.multiplier;
        return current;
      });
      answer = term;
      final lastTerm = terms.last;
      // 典型的な誤解: 倍率ではなく直前の項を足してしまう（lastTerm*2）。
      offsets = [lastTerm * 2 - answer, template.multiplier, -template.multiplier, template.multiplier * 2];
    } else {
      final stepSpan = template.stepMax - template.stepMin + 1;
      final stepMagnitude = max(template.stepMin + _random.nextInt(stepSpan), 1);
      final step = template.descending ? -stepMagnitude : stepMagnitude;
      terms = List<int>.generate(template.length, (i) => start + step * i);
      answer = start + step * template.length;
      offsets = [step, -step, step * 2, -step * 2];
    }

    final choices = <int>{answer};
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
        'terms': terms.join(','),
        if (template.scenarioId.isNotEmpty) 'scenarioId': template.scenarioId,
      },
    );
  }

  @override
  bool checkAnswer(Question question, String chosenId) => question.answer == chosenId;
}
