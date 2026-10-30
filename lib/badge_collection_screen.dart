import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'badge_image_resolver.dart';
import 'l10n/app_localizations.dart';
import 'unit_name_resolver.dart';

/// 単元ごとの「マスター済み/まとめテスト合格」バッジと、学習全体の達成バッジ
/// (連続学習日数・累計正解数・キャラコレクション達成度)を一覧表示する独立
/// 画面。無限に出題される設計のため、キャラコレクションと同様に「集める
/// 楽しみ」「やった感」を恒久的に確認できる場所をここに用意する。
class BadgeCollectionScreen extends StatelessWidget {
  const BadgeCollectionScreen({
    super.key,
    required this.units,
    required this.masteredUnitIds,
    this.testPassedUnitIds = const {},
    this.currentStreakDays = 0,
    this.totalCorrectAnswers = 0,
    this.ownedCharacterCount = 0,
    this.totalCharacterCount = 0,
  });

  final List<Unit> units;
  final Set<String> masteredUnitIds;
  final Set<String> testPassedUnitIds;
  final int currentStreakDays;
  final int totalCorrectAnswers;
  final int ownedCharacterCount;
  final int totalCharacterCount;

  static const _achievementEvaluator = AchievementEvaluator();
  static const _collectionDetector = CollectionCompletionDetector();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    final masteredCount = eligibleUnits.where((u) => masteredUnitIds.contains(u.id)).length;
    final totalCount = eligibleUnits.length;
    final progress = totalCount == 0 ? 0.0 : masteredCount / totalCount;

    final unlockedAchievements = _achievementEvaluator.evaluate(
      GrowthSnapshot(
        currentStreakDays: currentStreakDays,
        totalCorrectAnswers: totalCorrectAnswers,
      ),
    );
    final collectionMilestonesReached = [
      for (final ratio in _collectionDetector.milestoneRatios)
        ownedCharacterCount / (totalCharacterCount == 0 ? 1 : totalCharacterCount) >= ratio &&
            totalCharacterCount > 0,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgeCollectionTitle)),
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
                      l10n.badgeProgressText(masteredCount, totalCount),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (final unit in eligibleUnits)
                          _UnitBadgeCard(
                            key: Key('badgeCard_${unit.id}'),
                            label: resolveUnitName(l10n, unit.id),
                            mastered: masteredUnitIds.contains(unit.id),
                            testPassed: testPassedUnitIds.contains(unit.id),
                            strandId: strandIdForUnit(unit.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.achievementSectionTitle,
                      key: const Key('achievementSectionTitle'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_streakDays3'),
                          asset: 'assets/badges/badge_streak_3days.png',
                          label: l10n.achievementStreakDays3Title,
                          unlocked: unlockedAchievements.contains(AchievementId.streakDays3),
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_streakDays7'),
                          asset: 'assets/badges/badge_streak_7days.png',
                          label: l10n.achievementStreakDays7Title,
                          unlocked: unlockedAchievements.contains(AchievementId.streakDays7),
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_streakDays30'),
                          asset: 'assets/badges/badge_streak_30days.png',
                          label: l10n.achievementStreakDays30Title,
                          unlocked: unlockedAchievements.contains(AchievementId.streakDays30),
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_correctAnswers100'),
                          asset: 'assets/badges/badge_correct_100.png',
                          label: l10n.achievementCorrectAnswers100Title,
                          unlocked: unlockedAchievements.contains(AchievementId.correctAnswers100),
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_correctAnswers500'),
                          asset: 'assets/badges/badge_correct_500.png',
                          label: l10n.achievementCorrectAnswers500Title,
                          unlocked: unlockedAchievements.contains(AchievementId.correctAnswers500),
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_collection50'),
                          asset: 'assets/badges/badge_collection_50.png',
                          label: l10n.achievementCollection50Title,
                          unlocked: collectionMilestonesReached[0],
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_collection80'),
                          asset: 'assets/badges/badge_collection_80.png',
                          label: l10n.achievementCollection80Title,
                          unlocked: collectionMilestonesReached[1],
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_collection100'),
                          asset: 'assets/badges/badge_collection_100.png',
                          label: l10n.achievementCollection100Title,
                          unlocked: collectionMilestonesReached[2],
                        ),
                      ],
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

class _UnitBadgeCard extends StatelessWidget {
  const _UnitBadgeCard({
    super.key,
    required this.label,
    required this.mastered,
    required this.testPassed,
    required this.strandId,
  });

  final String label;
  final bool mastered;
  final bool testPassed;
  final String? strandId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strand = strandId;
    final badgeAsset = strand == null
        ? null
        : (testPassed ? testPassBadgeAsset(strand) : masteryBadgeAsset(strand));
    final unlocked = mastered || testPassed;
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: badgeAsset == null
                ? CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        unlocked ? Colors.amber : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.emoji_events,
                      color: unlocked ? Colors.white : theme.colorScheme.outline,
                      size: 28,
                    ),
                  )
                : _BadgeImage(asset: badgeAsset, unlocked: unlocked),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// バッジ画像を、未獲得時は薄いグレースケール表示に、獲得済みは通常表示に
/// 切り替える共通ウィジェット(単元バッジ・達成バッジの両方で使う)。
class _BadgeImage extends StatelessWidget {
  const _BadgeImage({required this.asset, required this.unlocked});

  final String asset;
  final bool unlocked;

  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(asset, fit: BoxFit.contain);
    if (unlocked) return image;
    return Opacity(
      opacity: 0.35,
      child: ColorFiltered(colorFilter: _grayscale, child: image),
    );
  }
}

class _AchievementBadgeCard extends StatelessWidget {
  const _AchievementBadgeCard({
    super.key,
    required this.asset,
    required this.label,
    required this.unlocked,
  });

  final String asset;
  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: _BadgeImage(asset: asset, unlocked: unlocked),
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
