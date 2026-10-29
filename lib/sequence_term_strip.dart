import 'package:flutter/material.dart';

/// 数列(sequence)問題向けの体験型補助ウィジェット。既出の項を横に並べて
/// 見せ、最後に「?」を置くことでパターンの続きを考える体験を視覚化する。
/// 実際の回答は既存の選択肢ボタン/ドラッグ&ドロップが担う。
class SequenceTermStrip extends StatelessWidget {
  const SequenceTermStrip({super.key, required this.terms});

  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip(String label, {required Key key, bool isPlaceholder = false}) {
      return Container(
        key: key,
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlaceholder
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isPlaceholder ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isPlaceholder ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isPlaceholder ? theme.colorScheme.onPrimaryContainer : null,
          ),
        ),
      );
    }

    return Wrap(
      key: const Key('sequenceTermStrip'),
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < terms.length; i++) chip(terms[i], key: Key('sequenceTerm_$i')),
        chip('?', key: const Key('sequenceTermQuestionMark'), isPlaceholder: true),
      ],
    );
  }
}
