import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// 測定(単位変換)問題向けの体験型補助ウィジェット。小さなタイルを1つずつ
/// タップして数えることで、数値の大きさを実感しながら数えられるようにする。
/// 正誤判定は既存の選択肢ボタン/ドラッグ&ドロップが担い、これは見た目専用。
class UnitTallyCounter extends StatefulWidget {
  const UnitTallyCounter({super.key, required this.count});

  /// タイルの数(UIが煩雑にならないよう呼び出し側で上限を掛けておくこと)。
  final int count;

  @override
  State<UnitTallyCounter> createState() => _UnitTallyCounterState();
}

class _UnitTallyCounterState extends State<UnitTallyCounter> {
  late Set<int> _tappedIndexes = {};

  @override
  void didUpdateWidget(covariant UnitTallyCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _tappedIndexes = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < widget.count; i++)
              Builder(builder: (context) {
                final tapped = _tappedIndexes.contains(i);
                return Semantics(
                  button: true,
                  toggled: tapped,
                  label: l10n.unitTallyTileSemanticLabel(i + 1),
                  child: GestureDetector(
                    key: Key('unitTallyTile_$i'),
                    onTap: () => setState(() {
                      if (tapped) {
                        _tappedIndexes.remove(i);
                      } else {
                        _tappedIndexes.add(i);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: tapped
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tallyCounterLabel(_tappedIndexes.length),
          key: const Key('unitTallyCounterText'),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
