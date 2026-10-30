import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';
import 'unit_name_resolver.dart';

/// 「ゲームで学ぶ」で挑戦する単元を選ぶ画面。どの単元を選んでも、出題画面
/// (question_screen.dart)側の体験型インタラクション(タップで数える・
/// ドラッグ&ドロップ・棒グラフタップ等)で遊びながら学べる。
/// ロック中の単元は鍵アイコンで、マスター済みの単元はトロフィーバッジで
/// 一目で分かるようにする(実際のロック解除判定・SnackBar表示は
/// [onUnitTap]経由でホーム画面側の`_openUnit`が担う)。
/// 毎日使いたくなる仕掛けとして、日付ごとに決定的な「今日の挑戦」単元を
/// 先頭に表示する(サーバー同期不要・端末日付のみで完結する簡易実装)。
class GameModeUnitPickerScreen extends StatelessWidget {
  GameModeUnitPickerScreen({
    super.key,
    required this.units,
    required this.onUnitTap,
    this.lockedUnitIds = const {},
    this.masteredUnitIds = const {},
    this.onFamilyChallengeTap,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  final List<Unit> units;
  final Future<void> Function(BuildContext context, Unit unit) onUnitTap;
  final Set<String> lockedUnitIds;
  final Set<String> masteredUnitIds;
  final DateTime now;

  /// 指定時、「家族で挑戦しよう」カードを表示し、タップで親も交わって
  /// 遊べるファミリーチャレンジへ誘導する(親も交わって遊びながら学べる
  /// 機能との連携)。未指定ならカード自体を表示しない。
  final void Function(BuildContext context)? onFamilyChallengeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    final masteredCount = eligibleUnits.where((u) => masteredUnitIds.contains(u.id)).length;
    final totalCount = eligibleUnits.length;
    final progress = totalCount == 0 ? 0.0 : masteredCount / totalCount;
    final dailyUnitId = dailyFeaturedUnitId(
      now,
      eligibleUnits.where((u) => !lockedUnitIds.contains(u.id)).map((u) => u.id).toList(),
    );
    Unit? dailyUnit;
    for (final u in eligibleUnits) {
      if (u.id == dailyUnitId) {
        dailyUnit = u;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameModeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.gameModePickUnitBody),
          const SizedBox(height: 16),
          if (dailyUnit case final featuredUnit?)
            Card(
              key: const Key('dailyChallengeCard'),
              color: theme.colorScheme.secondaryContainer,
              child: ListTile(
                leading: Icon(Icons.today, color: theme.colorScheme.onSecondaryContainer),
                title: Text(
                  l10n.dailyChallengeLabel,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${l10n.dailyChallengeSubtitle}\n${resolveUnitName(l10n, featuredUnit.id)}',
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                ),
                isThreeLine: true,
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSecondaryContainer),
                onTap: () => onUnitTap(context, featuredUnit),
              ),
            ),
          if (onFamilyChallengeTap case final onTap?)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                key: const Key('gameModeFamilyChallengeCard'),
                color: theme.colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: Icon(Icons.diversity_3, color: theme.colorScheme.onTertiaryContainer),
                  title: Text(
                    l10n.familyChallengeTile,
                    style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                  ),
                  subtitle: Text(
                    l10n.familyChallengeTileSubtitle,
                    style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                  ),
                  trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onTertiaryContainer),
                  onTap: () => onTap(context),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // 「ゲームで学ぶ」だけの進捗を可視化し、遊ぶたびに実績が増えていく
          // 感覚(やった感)を持てるようにする。
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.gameModeProgressLabel(masteredCount, totalCount),
                    key: const Key('gameModeProgressText'),
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
          for (final unit in eligibleUnits)
            Card(
              child: ListTile(
                key: Key('gameModeUnitOption_${unit.id}'),
                leading: Icon(
                  lockedUnitIds.contains(unit.id)
                      ? Icons.lock_outline
                      : Icons.sports_esports_outlined,
                  color: lockedUnitIds.contains(unit.id) ? theme.colorScheme.outline : null,
                ),
                title: Text(
                  resolveUnitName(l10n, unit.id),
                  style: lockedUnitIds.contains(unit.id)
                      ? TextStyle(color: theme.colorScheme.outline)
                      : null,
                ),
                trailing: masteredUnitIds.contains(unit.id)
                    ? Icon(
                        Icons.emoji_events,
                        key: Key('gameModeUnitMasteredBadge_${unit.id}'),
                        color: Colors.amber,
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => onUnitTap(context, unit),
              ),
            ),
        ],
      ),
    );
  }
}
