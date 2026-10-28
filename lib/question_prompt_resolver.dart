import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';
import 'word_problem_resolver.dart';

/// 問題種別(算数/図形/測定/データ)ごとにQuestionのparamsから出題文を組み立てる。
/// コア側はIDと数値のみ保持し、文言はアプリのl10nに委ねる設計（ADR参照）。
/// 対応するパターンが無い場合（数列など）はnullを返す。
String? resolveQuestionPrompt(AppLocalizations l10n, Question question) {
  final params = question.params;
  if (params.containsKey('a') && params.containsKey('b')) {
    return resolveArithmeticPrompt(
      l10n,
      operator: params['operator'] ?? '',
      a: int.parse(params['a']!),
      b: int.parse(params['b']!),
      wordProblemId: params['wordProblemId'],
    );
  }
  if (params.containsKey('shapeNameKey')) {
    return _resolveShapePrompt(l10n, params);
  }
  if (params.containsKey('fromUnitKey') && params.containsKey('toUnitKey')) {
    return _resolveMeasurementPrompt(l10n, params);
  }
  if (params.containsKey('values') && params.containsKey('operation')) {
    return _resolveDatasetPrompt(l10n, params);
  }
  if (params.containsKey('terms')) {
    return _resolveSequencePrompt(l10n, params);
  }
  return null;
}

String _resolveSequencePrompt(AppLocalizations l10n, Map<String, String> params) {
  final terms = params['terms']!.split(',').join(', ');
  switch (params['scenarioId']) {
    case 'scenario_savings':
      return l10n.sequenceScenarioSavings(terms);
    case 'scenario_plant':
      return l10n.sequenceScenarioPlant(terms);
    default:
      return l10n.sequencePrompt(terms);
  }
}

String _resolveShapeName(AppLocalizations l10n, String shapeNameKey) {
  switch (shapeNameKey) {
    case 'shape_triangle':
      return l10n.shapeNameTriangle;
    case 'shape_square':
      return l10n.shapeNameSquare;
    case 'shape_pentagon':
      return l10n.shapeNamePentagon;
    case 'shape_hexagon':
      return l10n.shapeNameHexagon;
    case 'shape_heptagon':
      return l10n.shapeNameHeptagon;
    case 'shape_octagon':
      return l10n.shapeNameOctagon;
    default:
      return shapeNameKey;
  }
}

String _resolveShapePrompt(AppLocalizations l10n, Map<String, String> params) {
  final shapeName = _resolveShapeName(l10n, params['shapeNameKey']!);
  final isDiagonals = params['questionKind'] == 'diagonals';
  switch (params['scenarioId']) {
    case 'scenario_garden':
      return isDiagonals
          ? l10n.shapeScenarioGardenDiagonals(shapeName)
          : l10n.shapeScenarioGardenSides(shapeName);
    default:
      return isDiagonals
          ? l10n.shapePromptDiagonals(shapeName)
          : l10n.shapePromptSides(shapeName);
  }
}

String _resolveUnitName(AppLocalizations l10n, String unitKey) {
  switch (unitKey) {
    case 'unit_cm':
      return l10n.unitNameCm;
    case 'unit_m':
      return l10n.unitNameM;
    case 'unit_km':
      return l10n.unitNameKm;
    case 'unit_g':
      return l10n.unitNameG;
    case 'unit_kg':
      return l10n.unitNameKg;
    case 'unit_ml':
      return l10n.unitNameMl;
    case 'unit_l':
      return l10n.unitNameL;
    case 'unit_mm':
      return l10n.unitNameMm;
    default:
      return unitKey;
  }
}

String _resolveMeasurementPrompt(AppLocalizations l10n, Map<String, String> params) {
  final toUnit = _resolveUnitName(l10n, params['toUnitKey']!);
  final value = int.parse(params['value']!);
  final fromUnit = _resolveUnitName(l10n, params['fromUnitKey']!);
  switch (params['scenarioId']) {
    case 'scenario_classroom':
      return l10n.measurementScenarioClassroom(value, fromUnit, toUnit);
    case 'scenario_canteen':
      return l10n.measurementScenarioCanteen(value, fromUnit, toUnit);
    case 'scenario_pencil':
      return l10n.measurementScenarioPencil(value, fromUnit, toUnit);
    case 'scenario_trip':
      return l10n.measurementScenarioTrip(value, fromUnit, toUnit);
    case 'scenario_juice':
      return l10n.measurementScenarioJuice(value, fromUnit, toUnit);
    default:
      return l10n.measurementPrompt(toUnit, value, fromUnit);
  }
}

String _resolveDatasetPrompt(AppLocalizations l10n, Map<String, String> params) {
  final values = params['values']!.split(',').join(', ');
  switch (params['scenarioId']) {
    case 'scenario_pushups':
      return l10n.datasetScenarioPushups(values);
    case 'scenario_recess':
      return l10n.datasetScenarioRecess(values);
  }
  switch (params['operation']) {
    case 'max':
      return l10n.datasetPromptMax(values);
    case 'min':
      return l10n.datasetPromptMin(values);
    case 'sum':
      return l10n.datasetPromptSum(values);
    case 'range':
      return l10n.datasetPromptRange(values);
    case 'mode':
    default:
      return l10n.datasetPromptMode(values);
  }
}
