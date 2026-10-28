import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'character_card.dart';
import 'character_definition.dart';

/// 12体のコレクションキャラを一覧表示する独立画面。所持数/全体数の進捗と、
/// 節目到達（`CollectionCompletionDetector`、coreのgrowthモジュール）の
/// お祝い表示を含む。
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.snapshot});

  final CharacterCollectionSnapshot snapshot;

  static const _completionDetector = CollectionCompletionDetector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownedCount = snapshot.ownedCount;
    final totalCount = characterDefinitions.length;
    final progress = totalCount == 0 ? 0.0 : ownedCount / totalCount;
    final milestoneReached = _completionDetector.isMilestoneReached(ownedCount, totalCount);

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Coleção')),
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
                      '$ownedCount / $totalCount personagens coletados',
                      key: const Key('collectionProgressText'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress, minHeight: 10),
                    ),
                    if (milestoneReached) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.celebration, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Você está quase lá!',
                            key: const Key('collectionMilestoneText'),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final def in characterDefinitions)
                      CharacterCard(
                        key: Key('characterCard_${def.id}'),
                        definition: def,
                        level: snapshot.levelOf(def.id),
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
