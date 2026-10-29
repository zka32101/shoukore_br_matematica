import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';
import 'unit_name_resolver.dart';

/// 「ゲームで学ぶ」で挑戦する単元を選ぶ画面。どの単元を選んでも、出題画面
/// (question_screen.dart)側の体験型インタラクション(タップで数える・
/// ドラッグ&ドロップ・棒グラフタップ等)で遊びながら学べる。
class GameModeUnitPickerScreen extends StatelessWidget {
  const GameModeUnitPickerScreen({super.key, required this.units, required this.onUnitTap});

  final List<Unit> units;
  final Future<void> Function(BuildContext context, Unit unit) onUnitTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameModeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.gameModePickUnitBody),
          const SizedBox(height: 16),
          for (final unit in eligibleUnits)
            Card(
              child: ListTile(
                key: Key('gameModeUnitOption_${unit.id}'),
                leading: const Icon(Icons.sports_esports_outlined),
                title: Text(resolveUnitName(l10n, unit.id)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onUnitTap(context, unit),
              ),
            ),
        ],
      ),
    );
  }
}
