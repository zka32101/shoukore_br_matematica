import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';
import 'question_cache.dart';
import 'unit_name_resolver.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({
    super.key,
    required this.unitIds,
    required this.progressStore,
    required this.clock,
    required this.questionCache,
    this.unitTestPassedIds = const {},
  });

  final List<String> unitIds;
  final ProgressStore progressStore;
  final Clock clock;
  final QuestionCache questionCache;

  /// 単元まとめテスト(到達点モード)に合格済みの単元ID。保護者が一目で
  /// 到達点を把握できるよう、各単元の行に合格バッジを添える。
  final Set<String> unitTestPassedIds;

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  static const _builder = WeeklyReportBuilder();

  WeeklyReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final report = await _builder.build(
      progressStore: widget.progressStore,
      unitIds: widget.unitIds,
      clock: widget.clock,
      questionLookup: widget.questionCache.lookup,
    );
    if (!mounted) return;
    setState(() => _report = report);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklyReportTitle)),
      body: report == null
          ? const Center(child: CircularProgressIndicator())
          : report.totalAttempts == 0
              ? Center(
                  key: const Key('weeklyReportNoDataText'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.weeklyReportNoData,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  key: const Key('weeklyReportList'),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
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
                                    value: report.overallAccuracy,
                                    strokeWidth: 6,
                                    backgroundColor: theme.colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.15),
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  Icon(
                                    Icons.query_stats,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                // 生成コードの引数は、名前のアルファベット順(correct, percent, total)。
                                l10n.weeklyReportAccuracy(
                                  report.totalCorrect,
                                  (report.overallAccuracy * 100).round(),
                                  report.totalAttempts,
                                ),
                                key: const Key('weeklyReportAccuracyText'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final unit in report.units)
                      Card(
                        key: Key('weeklyReportUnit_${unit.unitId}'),
                        child: ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          // 引数は、名前のアルファベット順(correct, percent, total, unitName)。
                          title: Text(l10n.weeklyReportUnitLine(
                            unit.correctCount,
                            (unit.accuracy * 100).round(),
                            unit.attemptCount,
                            resolveUnitName(l10n, unit.unitId),
                          )),
                          subtitle: unit.topMisconception != null
                              ? Text(
                                  l10n.weeklyReportTopMisconception(unit.topMisconception!),
                                  style: theme.textTheme.bodySmall,
                                )
                              : null,
                          trailing: widget.unitTestPassedIds.contains(unit.unitId)
                              ? Icon(
                                  Icons.verified,
                                  key: const Key('weeklyReportUnitTestPassedIcon'),
                                  color: Colors.amber[800],
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
    );
  }
}
