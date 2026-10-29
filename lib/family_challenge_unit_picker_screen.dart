import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'family_challenge_screen.dart';
import 'growth_repository.dart';
import 'l10n/app_localizations.dart';
import 'question_cache.dart';
import 'unit_name_resolver.dart';

/// 「親も交わって遊びながら学べる」ファミリーチャレンジで挑戦する単元を選ぶ画面。
class FamilyChallengeUnitPickerScreen extends StatelessWidget {
  const FamilyChallengeUnitPickerScreen({
    super.key,
    required this.units,
    required this.source,
    required this.progressStore,
    required this.growthRepository,
    required this.clock,
    required this.questionCache,
  });

  final List<Unit> units;
  final QuestionSource source;
  final ProgressStore progressStore;
  final GrowthRepository growthRepository;
  final Clock clock;
  final QuestionCache questionCache;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eligibleUnits = units.where((u) => u.templateIds.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyChallengeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.familyChallengePickUnitBody),
          const SizedBox(height: 16),
          for (final unit in eligibleUnits)
            Card(
              child: ListTile(
                key: Key('familyChallengeUnitOption_${unit.id}'),
                title: Text(resolveUnitName(l10n, unit.id)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FamilyChallengeScreen(
                      unit: unit,
                      source: source,
                      progressStore: progressStore,
                      growthRepository: growthRepository,
                      clock: clock,
                      questionCache: questionCache,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
