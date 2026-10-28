import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

/// 単元ごとの「マスター済み」バッジを一覧表示する独立画面。無限に出題される
/// 設計のため、キャラコレクションと同様に「集める楽しみ」「やった感」を
/// 恒久的に確認できる場所をここに用意する。
class BadgeCollectionScreen extends StatelessWidget {
  const BadgeCollectionScreen({
    super.key,
    required this.units,
    required this.masteredUnitIds,
  });

  final List<Unit> units;
  final Set<String> masteredUnitIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    final masteredCount = eligibleUnits.where((u) => masteredUnitIds.contains(u.id)).length;
    final totalCount = eligibleUnits.length;
    final progress = totalCount == 0 ? 0.0 : masteredCount / totalCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Medalhas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$masteredCount / $totalCount unidades dominadas',
                      key: const Key('badgeProgressText'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress, minHeight: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final unit in eligibleUnits)
                      _BadgeCard(
                        key: Key('badgeCard_${unit.id}'),
                        label: unit.id,
                        mastered: masteredUnitIds.contains(unit.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({super.key, required this.label, required this.mastered});

  final String label;
  final bool mastered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: mastered ? Colors.amber : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.emoji_events,
              color: mastered ? Colors.white : theme.colorScheme.outline,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
