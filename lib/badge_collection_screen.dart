import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'badge_image_resolver.dart';
import 'l10n/app_localizations.dart';
import 'unit_name_resolver.dart';

/// 単元ごとの「マスター済み/まとめテスト合格」バッジと、学習全体の達成バッジ
/// (連続学習日数・累計正解数・キャラコレクション達成度)を一覧表示する独立
/// 画面。無限に出題される設計のため、キャラコレクションと同様に「集める
/// 楽しみ」「やった感」を恒久的に確認できる場所をここに用意する。
/// ストランド(eixo)ごとにグルーピングし、未獲得バッジには次の節目までの
/// 目安を表示することで、ただ並べるだけでなく「次は何を目指せばいいか」が
/// 一目で分かるようにしている。
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
  static const _achievementProximityHint = AchievementProximityHint();
  static const _collectionProximityHint = CollectionCompletionProximityHint();
  static const _strandOrder = ['numbers', 'algebra', 'geometry', 'measurement', 'statistics'];

  String _strandLabel(AppLocalizations l10n, String strandId) => switch (strandId) {
        'numbers' => l10n.mathGuideSectionNumeros,
        'algebra' => l10n.mathGuideSectionAlgebra,
        'geometry' => l10n.mathGuideSectionGeometria,
        'measurement' => l10n.mathGuideSectionGrandezas,
        'statistics' => l10n.mathGuideSectionProbabilidade,
        _ => strandId,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    final masteredCount = eligibleUnits.where((u) => masteredUnitIds.contains(u.id)).length;
    final totalCount = eligibleUnits.length;
    final progress = totalCount == 0 ? 0.0 : masteredCount / totalCount;

    final snapshot = GrowthSnapshot(
      currentStreakDays: currentStreakDays,
      totalCorrectAnswers: totalCorrectAnswers,
    );
    final unlockedAchievements = _achievementEvaluator.evaluate(snapshot);
    final remainingToUnlock = _achievementProximityHint.remainingToUnlock(snapshot);
    final collectionRatio =
        totalCharacterCount == 0 ? 0.0 : ownedCharacterCount / totalCharacterCount;
    final collectionMilestonesReached = [
      for (final milestone in _collectionDetector.milestoneRatios) collectionRatio >= milestone,
    ];
    final nextCollectionMilestoneRemaining = _collectionProximityHint.remainingToNextMilestone(
      ownedCharacterCount,
      totalCharacterCount,
    );
    final nextUnreachedMilestoneIndex =
        collectionMilestonesReached.indexWhere((reached) => !reached);

    final groupedUnits = <String, List<Unit>>{};
    for (final unit in eligibleUnits) {
      final strand = strandIdForUnit(unit.id);
      if (strand == null) continue;
      groupedUnits.putIfAbsent(strand, () => []).add(unit);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: Text(l10n.badgeCollectionTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BadgeProgressHeaderCard(
              progress: progress,
              progressText: l10n.badgeProgressText(masteredCount, totalCount),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final strandId in _strandOrder)
                      if (groupedUnits[strandId] case final strandUnits?)
                        _StrandSection(
                          key: Key('badgeStrandSection_$strandId'),
                          label: _strandLabel(l10n, strandId),
                          accentColor: strandAccentColor(strandId),
                          mastered: strandUnits.where((u) => masteredUnitIds.contains(u.id)).length,
                          total: strandUnits.length,
                          children: [
                            for (final unit in strandUnits)
                              _UnitBadgeCard(
                                key: Key('badgeCard_${unit.id}'),
                                label: resolveUnitName(l10n, unit.id),
                                mastered: masteredUnitIds.contains(unit.id),
                                testPassed: testPassedUnitIds.contains(unit.id),
                                strandId: strandId,
                                accentColor: strandAccentColor(strandId),
                              ),
                          ],
                        ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.military_tech, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          l10n.achievementSectionTitle,
                          key: const Key('achievementSectionTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
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
                          hintText: switch (remainingToUnlock[AchievementId.streakDays3]) {
                            final days? => l10n.achievementProgressDaysRemaining(days),
                            null => null,
                          },
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_streakDays7'),
                          asset: 'assets/badges/badge_streak_7days.png',
                          label: l10n.achievementStreakDays7Title,
                          unlocked: unlockedAchievements.contains(AchievementId.streakDays7),
                          hintText: switch (remainingToUnlock[AchievementId.streakDays7]) {
                            final days? => l10n.achievementProgressDaysRemaining(days),
                            null => null,
                          },
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_streakDays30'),
                          asset: 'assets/badges/badge_streak_30days.png',
                          label: l10n.achievementStreakDays30Title,
                          unlocked: unlockedAchievements.contains(AchievementId.streakDays30),
                          hintText: switch (remainingToUnlock[AchievementId.streakDays30]) {
                            final days? => l10n.achievementProgressDaysRemaining(days),
                            null => null,
                          },
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_correctAnswers100'),
                          asset: 'assets/badges/badge_correct_100.png',
                          label: l10n.achievementCorrectAnswers100Title,
                          unlocked: unlockedAchievements.contains(AchievementId.correctAnswers100),
                          hintText: switch (remainingToUnlock[AchievementId.correctAnswers100]) {
                            final count? => l10n.achievementProgressCorrectRemaining(count),
                            null => null,
                          },
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_correctAnswers500'),
                          asset: 'assets/badges/badge_correct_500.png',
                          label: l10n.achievementCorrectAnswers500Title,
                          unlocked: unlockedAchievements.contains(AchievementId.correctAnswers500),
                          hintText: switch (remainingToUnlock[AchievementId.correctAnswers500]) {
                            final count? => l10n.achievementProgressCorrectRemaining(count),
                            null => null,
                          },
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_collection50'),
                          asset: 'assets/badges/badge_collection_50.png',
                          label: l10n.achievementCollection50Title,
                          unlocked: collectionMilestonesReached[0],
                          hintText: nextUnreachedMilestoneIndex == 0 &&
                                  nextCollectionMilestoneRemaining != null
                              ? l10n.achievementProgressCollectionRemaining(
                                  nextCollectionMilestoneRemaining,
                                )
                              : null,
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_collection80'),
                          asset: 'assets/badges/badge_collection_80.png',
                          label: l10n.achievementCollection80Title,
                          unlocked: collectionMilestonesReached[1],
                          hintText: nextUnreachedMilestoneIndex == 1 &&
                                  nextCollectionMilestoneRemaining != null
                              ? l10n.achievementProgressCollectionRemaining(
                                  nextCollectionMilestoneRemaining,
                                )
                              : null,
                        ),
                        _AchievementBadgeCard(
                          key: const Key('achievementCard_collection100'),
                          asset: 'assets/badges/badge_collection_100.png',
                          label: l10n.achievementCollection100Title,
                          unlocked: collectionMilestonesReached[2],
                          hintText: nextUnreachedMilestoneIndex == 2 &&
                                  nextCollectionMilestoneRemaining != null
                              ? l10n.achievementProgressCollectionRemaining(
                                  nextCollectionMilestoneRemaining,
                                )
                              : null,
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

class _BadgeProgressHeaderCard extends StatelessWidget {
  const _BadgeProgressHeaderCard({required this.progress, required this.progressText});

  final double progress;
  final String progressText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  Icon(Icons.emoji_events, color: theme.colorScheme.onPrimaryContainer, size: 24),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                progressText,
                key: const Key('badgeProgressText'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrandSection extends StatelessWidget {
  const _StrandSection({
    super.key,
    required this.label,
    required this.accentColor,
    required this.mastered,
    required this.total,
    required this.children,
  });

  final String label;
  final Color accentColor;
  final int mastered;
  final int total;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$mastered/$total',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 16, children: children),
        ],
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
    required this.accentColor,
  });

  final String label;
  final bool mastered;
  final bool testPassed;
  final String? strandId;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strand = strandId;
    final badgeAsset = strand == null
        ? null
        : (testPassed ? testPassBadgeAsset(strand) : masteryBadgeAsset(strand));
    final unlocked = mastered || testPassed;
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          _BadgeMedallion(
            accentColor: accentColor,
            unlocked: unlocked,
            child: badgeAsset == null
                ? Icon(
                    Icons.emoji_events,
                    color: unlocked ? Colors.white : theme.colorScheme.outline,
                    size: 28,
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

/// バッジ画像を円形の「メダリオン」として飾る共通フレーム。獲得済みは
/// 差し色のグラデーション円+金リング+淡いグロー、未獲得は灰色の点線枠で
/// 「ここに何かが入る」ことが分かるようにする。
class _BadgeMedallion extends StatelessWidget {
  const _BadgeMedallion({
    required this.child,
    required this.accentColor,
    required this.unlocked,
  });

  final Widget child;
  final Color accentColor;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!unlocked) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: child,
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [accentColor.withValues(alpha: 0.25), accentColor.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: Colors.amber, width: 2.5),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: child,
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
      opacity: 0.45,
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
    this.hintText,
  });

  final String asset;
  final String label;
  final bool unlocked;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          _BadgeMedallion(
            accentColor: theme.colorScheme.primary,
            unlocked: unlocked,
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
          if (!unlocked && hintText != null)
            Text(
              hintText!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }
}
