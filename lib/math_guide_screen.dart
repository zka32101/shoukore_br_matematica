import 'package:flutter/material.dart';

import 'explanation_resolver.dart';
import 'l10n/app_localizations.dart';

/// JP版(sansu-kore)の「算数ガイド」に相当する、単元を解くコツをまとめて
/// 振り返れる画面。アプリ内に既にある解説文言(explanationId→l10n、
/// ADR準拠でコア側はIDのみ保持)を、eixo(分野)ごとにまとめて表示する。
/// 新しい解説文言は作らず、既存のものを一覧にして振り返りやすくする。
class MathGuideScreen extends StatelessWidget {
  const MathGuideScreen({super.key});

  static const _sections = <(String titleKey, IconData, Color, List<String>)>[
    (
      'mathGuideSectionNumeros',
      Icons.numbers,
      Colors.indigo,
      ['explanation_add', 'explanation_subtract', 'explanation_multiply', 'explanation_divide'],
    ),
    (
      'mathGuideSectionAlgebra',
      Icons.functions,
      Colors.deepPurple,
      [
        'explanation_sequence',
        'explanation_sequence_descending',
        'explanation_sequence_multiplicative',
      ],
    ),
    (
      'mathGuideSectionGeometria',
      Icons.change_history,
      Colors.teal,
      [
        'explanation_shape_triangle',
        'explanation_shape_square',
        'explanation_shape_pentagon',
        'explanation_shape_hexagon',
        'explanation_shape_heptagon',
        'explanation_shape_octagon',
        'explanation_diagonals',
      ],
    ),
    (
      'mathGuideSectionGrandezas',
      Icons.straighten,
      Colors.orange,
      [
        'explanation_unit_mm_to_cm',
        'explanation_unit_cm_to_mm',
        'explanation_unit_cm_to_m',
        'explanation_unit_m_to_cm',
        'explanation_unit_m_to_km',
        'explanation_unit_km_to_m',
        'explanation_unit_g_to_kg',
        'explanation_unit_kg_to_g',
        'explanation_unit_ml_to_l',
        'explanation_unit_l_to_ml',
      ],
    ),
    (
      'mathGuideSectionProbabilidade',
      Icons.bar_chart,
      Colors.pink,
      [
        'explanation_dataset_max',
        'explanation_dataset_min',
        'explanation_dataset_mode',
        'explanation_dataset_sum',
        'explanation_dataset_range',
      ],
    ),
  ];

  String _sectionTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'mathGuideSectionNumeros':
        return l10n.mathGuideSectionNumeros;
      case 'mathGuideSectionAlgebra':
        return l10n.mathGuideSectionAlgebra;
      case 'mathGuideSectionGeometria':
        return l10n.mathGuideSectionGeometria;
      case 'mathGuideSectionGrandezas':
        return l10n.mathGuideSectionGrandezas;
      default:
        return l10n.mathGuideSectionProbabilidade;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mathGuideTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (titleKey, icon, color, explanationIds) in _sections) ...[
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  _sectionTitle(l10n, titleKey),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final explanationId in explanationIds)
              Card(
                key: Key('mathGuideCard_$explanationId'),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(resolveExplanation(l10n, explanationId) ?? ''),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
