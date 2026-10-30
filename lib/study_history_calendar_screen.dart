import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// 学習ストリーク(連続学習日数)を数字だけでなく、月間カレンダーとして
/// 可視化する画面。保護者が一目で子どもの継続状況を把握できるようにする
/// (CLAUDE.md共通要件「成長を実感できるもの」「毎日使いたくなるしかけ」)。
/// 専用の履歴ストアは持たず、既存の`ProgressStore`のAttempt履歴
/// (`answeredAt`)から「学習した日」を集計する。
class StudyHistoryCalendarScreen extends StatefulWidget {
  const StudyHistoryCalendarScreen({
    super.key,
    required this.unitIds,
    required this.progressStore,
    required this.clock,
  });

  final List<String> unitIds;
  final ProgressStore progressStore;
  final Clock clock;

  @override
  State<StudyHistoryCalendarScreen> createState() => _StudyHistoryCalendarScreenState();
}

class _StudyHistoryCalendarScreenState extends State<StudyHistoryCalendarScreen> {
  Set<DateTime>? _studiedDays;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.clock.now();
    _visibleMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    final days = <DateTime>{};
    for (final unitId in widget.unitIds) {
      final attempts = await widget.progressStore.getAttempts(unitId);
      for (final attempt in attempts) {
        final local = attempt.answeredAt.toLocal();
        days.add(DateTime(local.year, local.month, local.day));
      }
    }
    if (!mounted) return;
    setState(() => _studiedDays = days);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final studiedDays = _studiedDays;
    final locale = Localizations.localeOf(context).toString();
    final today = widget.clock.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.studyHistoryCalendarTitle)),
      body: studiedDays == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('studyCalendarPrevMonthButton'),
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMM(locale).format(_visibleMonth),
                          key: const Key('studyCalendarMonthLabel'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        key: const Key('studyCalendarNextMonthButton'),
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _WeekdayHeaderRow(locale: locale),
                  const SizedBox(height: 4),
                  _CalendarGrid(
                    month: _visibleMonth,
                    studiedDays: studiedDays,
                    today: todayDateOnly,
                    accentColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.studyHistoryCalendarLegend,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 日曜始まり(0)〜土曜(6)の曜日略称を、表示ロケールに合わせて生成する。
    final sunday = DateTime(2023, 1, 1); // 2023-01-01はちょうど日曜日。
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(
              DateFormat.E(locale).format(sunday.add(Duration(days: i))),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.studiedDays,
    required this.today,
    required this.accentColor,
  });

  final DateTime month;
  final Set<DateTime> studiedDays;
  final DateTime today;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday: 月=1〜日=7。日曜始まりのグリッドに合わせて先頭の
    // 空白セル数を求める(日曜なら0、月曜なら1、…、土曜なら6)。
    final leadingBlanks = firstOfMonth.weekday % 7;

    return GridView.builder(
      key: const Key('studyCalendarGrid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: leadingBlanks + daysInMonth,
      itemBuilder: (context, index) {
        if (index < leadingBlanks) return const SizedBox.shrink();
        final day = index - leadingBlanks + 1;
        final date = DateTime(month.year, month.month, day);
        final studied = studiedDays.contains(date);
        final isToday = date == today;
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            key: studied ? Key('studyCalendarStudiedDay_${date.toIso8601String()}') : null,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: studied ? accentColor : Colors.transparent,
              border: isToday ? Border.all(color: accentColor, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: studied ? Colors.white : null,
                fontWeight: isToday ? FontWeight.bold : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
