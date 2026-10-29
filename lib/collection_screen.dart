import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'character_card.dart';
import 'character_definition.dart';
import 'equipped_items.dart';
import 'l10n/app_localizations.dart';

/// 12体のコレクションキャラを一覧表示する独立画面。所持数/全体数の進捗と、
/// 節目到達（`CollectionCompletionDetector`、coreのgrowthモジュール）の
/// お祝い表示を含む。ショップで「使う」に設定したアイテム([equippedItems])が
/// あれば、各キャラの見た目に反映される。
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.snapshot, this.equippedItems});

  final CharacterCollectionSnapshot snapshot;
  final EquippedItems? equippedItems;

  static const _completionDetector = CollectionCompletionDetector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ownedCount = snapshot.ownedCount;
    final totalCount = characterDefinitions.length;
    final progress = totalCount == 0 ? 0.0 : ownedCount / totalCount;
    final milestoneReached = _completionDetector.isMilestoneReached(ownedCount, totalCount);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.collectionTitle)),
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
                      l10n.collectionProgressText(ownedCount, totalCount),
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
                            l10n.collectionMilestoneText,
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
                        equippedItems: equippedItems,
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
