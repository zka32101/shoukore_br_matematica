import 'l10n/app_localizations.dart';

/// `Question.explanationId`（コア共通の解説キー）をarb文言に解決する。
/// コア側はIDのみ保持し、実際の文言はアプリのl10nに委ねる設計（ADR参照）。
String? resolveExplanation(AppLocalizations l10n, String explanationId) {
  switch (explanationId) {
    case 'explanation_add':
      return l10n.explanationAdd;
    case 'explanation_subtract':
      return l10n.explanationSubtract;
    case 'explanation_multiply':
      return l10n.explanationMultiply;
    case 'explanation_divide':
      return l10n.explanationDivide;
    case 'explanation_sequence':
      return l10n.explanationSequence;
    case 'explanation_shape_triangle':
      return l10n.explanationShapeTriangle;
    case 'explanation_shape_square':
      return l10n.explanationShapeSquare;
    case 'explanation_shape_pentagon':
      return l10n.explanationShapePentagon;
    case 'explanation_shape_hexagon':
      return l10n.explanationShapeHexagon;
    case 'explanation_shape_heptagon':
      return l10n.explanationShapeHeptagon;
    case 'explanation_shape_octagon':
      return l10n.explanationShapeOctagon;
    case 'explanation_unit_cm_to_m':
      return l10n.explanationUnitCmToM;
    case 'explanation_unit_m_to_km':
      return l10n.explanationUnitMToKm;
    case 'explanation_unit_g_to_kg':
      return l10n.explanationUnitGToKg;
    case 'explanation_unit_ml_to_l':
      return l10n.explanationUnitMlToL;
    case 'explanation_dataset_max':
      return l10n.explanationDatasetMax;
    case 'explanation_dataset_min':
      return l10n.explanationDatasetMin;
    case 'explanation_dataset_mode':
      return l10n.explanationDatasetMode;
    case 'explanation_unit_m_to_cm':
      return l10n.explanationUnitMToCm;
    case 'explanation_unit_km_to_m':
      return l10n.explanationUnitKmToM;
    case 'explanation_unit_kg_to_g':
      return l10n.explanationUnitKgToG;
    case 'explanation_unit_l_to_ml':
      return l10n.explanationUnitLToMl;
    case 'explanation_sequence_descending':
      return l10n.explanationSequenceDescending;
    case 'explanation_diagonals':
      return l10n.explanationDiagonals;
    case 'explanation_dataset_sum':
      return l10n.explanationDatasetSum;
    case 'explanation_dataset_range':
      return l10n.explanationDatasetRange;
    default:
      return null;
  }
}
