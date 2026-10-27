import 'dart:convert';

import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'arithmetic_template.dart';
import 'geometry_template.dart';
import 'measurement_template.dart';
import 'sequence_template.dart';
import 'statistics_template.dart';

/// `curriculum/{locale}.json` の内容から単元ツリーとテンプレ定義を組み立てる。
/// `templates` 配列の各要素は `kind`（省略時は `arithmetic`）でテンプレ種別を判定する。
class CurriculumData {
  const CurriculumData({
    required this.units,
    required this.templates,
    this.shapeTemplates = const {},
    this.unitConversionTemplates = const {},
    this.sequenceTemplates = const {},
    this.dataSetTemplates = const {},
  });

  final List<Unit> units;

  /// BNCC Números（四則演算）向け。後方互換のため名称は据え置き。
  final Map<String, ArithmeticTemplate> templates;

  /// BNCC Geometria向け。
  final Map<String, ShapeTemplate> shapeTemplates;

  /// BNCC Grandezas e medidas向け。
  final Map<String, UnitConversionTemplate> unitConversionTemplates;

  /// BNCC Álgebra向け。
  final Map<String, SequencePatternTemplate> sequenceTemplates;

  /// BNCC Probabilidade e estatística向け。
  final Map<String, DataSetTemplate> dataSetTemplates;
}

CurriculumData parseCurriculum(String jsonContent) {
  final doc = jsonDecode(jsonContent) as Map<String, dynamic>;

  final templates = <String, ArithmeticTemplate>{};
  final shapeTemplates = <String, ShapeTemplate>{};
  final unitConversionTemplates = <String, UnitConversionTemplate>{};
  final sequenceTemplates = <String, SequencePatternTemplate>{};
  final dataSetTemplates = <String, DataSetTemplate>{};

  for (final raw in (doc['templates'] as List<dynamic>? ?? const [])) {
    final map = raw as Map<String, dynamic>;
    final kind = (map['kind'] as String?) ?? 'arithmetic';
    switch (kind) {
      case 'arithmetic':
        final tpl = ArithmeticTemplate.fromJson(map);
        templates[tpl.id] = tpl;
      case 'shape':
        final tpl = ShapeTemplate.fromJson(map);
        shapeTemplates[tpl.id] = tpl;
      case 'unitConversion':
        final tpl = UnitConversionTemplate.fromJson(map);
        unitConversionTemplates[tpl.id] = tpl;
      case 'sequence':
        final tpl = SequencePatternTemplate.fromJson(map);
        sequenceTemplates[tpl.id] = tpl;
      case 'dataset':
        final tpl = DataSetTemplate.fromJson(map);
        dataSetTemplates[tpl.id] = tpl;
      default:
        throw ArgumentError('unknown template kind: $kind');
    }
  }

  final units = (doc['units'] as List<dynamic>? ?? const [])
      .map((raw) => Unit.fromJson(raw as Map<String, dynamic>))
      .toList();

  return CurriculumData(
    units: units,
    templates: templates,
    shapeTemplates: shapeTemplates,
    unitConversionTemplates: unitConversionTemplates,
    sequenceTemplates: sequenceTemplates,
    dataSetTemplates: dataSetTemplates,
  );
}
