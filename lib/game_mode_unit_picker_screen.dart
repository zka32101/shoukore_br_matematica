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
class GameModeUnitPickerScreen extends StatelessWidget {
  const GameModeUnitPickerScreen({
    super.key,
    required this.units,
    required this.onUnitTap,
    this.lockedUnitIds = const {},
    this.masteredUnitIds = const {},
  });

  final List<Unit> units;
  final Future<void> Function(BuildContext context, Unit unit) onUnitTap;
  final Set<String> lockedUnitIds;
  final Set<String> masteredUnitIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    final masteredCount = eligibleUnits.where((u) => masteredUnitIds.contains(u.id)).length;
    final totalCount = eligibleUnits.length;
    final progress = totalCount == 0 ? 0.0 : masteredCount / totalCount;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameModeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.gameModePickUnitBody),
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
