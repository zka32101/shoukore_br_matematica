import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// 図形の辺を1つずつタップして数える体験型の学習補助ウィジェット。
/// 正誤判定そのものは既存の選択肢ボタン/ドラッグ&ドロップで行うため、
/// これは「数える」という操作そのものを体験させるための見た目専用の
/// マーカー群であり、回答結果には影響しない。
class ShapeTapCounter extends StatefulWidget {
  const ShapeTapCounter({super.key, required this.sides});

  final int sides;

  @override
  State<ShapeTapCounter> createState() => _ShapeTapCounterState();
}

class _ShapeTapCounterState extends State<ShapeTapCounter> {
  late Set<int> _tappedIndexes = {};

  @override
  void didUpdateWidget(covariant ShapeTapCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sides != widget.sides) {
      _tappedIndexes = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const size = 220.0;
    const radius = 90.0;
    const markerSize = 36.0;
    final center = size / 2;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < widget.sides; i++)
                Builder(builder: (context) {
                  // 辺の数だけ均等配置した円周上に、タップ可能なマーカーを置く
                  // (図形そのものの正確な作図ではなく、数える体験のための配置)。
                  final angle = (2 * math.pi * i / widget.sides) - math.pi / 2;
                  final x = center + radius * math.cos(angle) - markerSize / 2;
                  final y = center + radius * math.sin(angle) - markerSize / 2;
                  final tapped = _tappedIndexes.contains(i);
                  return Positioned(
                    left: x,
                    top: y,
                    child: GestureDetector(
                      key: Key('shapeEdgeMarker_$i'),
                      onTap: () => setState(() {
                        if (tapped) {
                          _tappedIndexes.remove(i);
                        } else {
                          _tappedIndexes.add(i);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: markerSize,
                        height: markerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tapped
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: tapped ? theme.colorScheme.onPrimary : theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.shapeTapCounterLabel(_tappedIndexes.length),
          key: const Key('shapeTapCounterText'),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
