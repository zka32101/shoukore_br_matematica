import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// データ分析(dataset)問題向けの体験型補助ウィジェット。棒グラフとして
/// 値を可視化し、バーをタップすることでも回答できるようにする
/// (タップでそのままonBarTap経由で採点される。既存の選択肢ボタン/
/// ドラッグ&ドロップでの回答も引き続き有効)。
class DatasetBarChart extends StatelessWidget {
  const DatasetBarChart({super.key, required this.values, required this.onBarTap});

  final List<int> values;
  final ValueChanged<String> onBarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    const maxBarHeight = 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.datasetBarChartHint,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: maxBarHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    label: l10n.datasetBarSemanticLabel(values[i].toString()),
                    child: GestureDetector(
                      key: Key('datasetBar_$i'),
                      onTap: () => onBarTap(values[i].toString()),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 28,
                            height: maxBarHeight * (values[i] / maxValue).clamp(0.08, 1.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${values[i]}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
