import 'package:flutter/material.dart';
// example独自の軽量InMemoryProgressStoreを使うため、コアが同名で公開している
// 実装（テスト・プロトタイピング用途向け）を隠す。
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

import 'age_gate_dialog.dart';
import 'curriculum_repository.dart';
import 'data_privacy_screen.dart';
import 'growth_repository.dart';
import 'guardian_dialog.dart';
import 'in_memory_progress_store.dart';
import 'l10n/app_localizations.dart';
import 'question_cache.dart';
import 'question_screen.dart';
import 'screen_time_repository.dart';
import 'src/question/arithmetic_question_source.dart';
import 'src/question/curriculum_loader.dart';
import 'weekly_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.entitlementReader});

  /// RevenueCat APIキー未設定（開発中・CI）の場合はnullのままにする。
  /// nullの場合、premiumToggleButtonは課金状態を模擬するデバッグ用トグルの
  /// ままになる。
  final EntitlementReader? entitlementReader;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _repository = CurriculumRepository();
  static const _clock = SystemClock();
  static const _locale = Locale('pt', 'BR');

  CurriculumData? _curriculum;
  ArithmeticQuestionSource? _source;
  GrowthRepository? _growthRepository;
  RegionalProfile? _regionalProfile;
  ScreenTimeRepository? _screenTimeRepository;
  final ScreenTimeStore _screenTimeStore = InMemoryScreenTimeStore();

  // pt_BRの既定ではscreenTimeLimitMinutesが0（無制限）のため、結合確認用に
  // 保護者が制限を設定した状態を模擬するトグルを用意する。
  bool _screenTimeLimitDemoEnabled = false;

  final ProgressStore _progressStore = InMemoryProgressStore();
  final GrowthStore _growthStore = InMemoryGrowthStore();
  final QuestionCache _questionCache = QuestionCache();
  final ConsentStore _consentStore = InMemoryConsentStore();
  ConsentRecord? _consent;

  final NotificationScheduler _notificationScheduler = InMemoryNotificationScheduler();
  static const _dailyReminderId = 'daily_reminder';
  DateTime? _dailyReminderScheduledAt;

  // 課金状態はアプリ側の責務（ADR参照）。実際の購入フローはストア申請時に実装し、
  // 現時点ではpremiumトグルで模擬する。
  Entitlement _entitlement = const Entitlement(unlockedSubjectIds: {});

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final curriculum = await _repository.loadCurriculum(_locale);
    final localeKey = _repository.localeKey(_locale);
    final source = ArithmeticQuestionSource(
      unitsByLocale: {localeKey: curriculum.units},
      templates: curriculum.templates,
    );
    final regionalProfile = await _repository.loadRegionalProfile(_locale);
    final growthRepository = await GrowthRepository.load(
      clock: _clock,
      profile: regionalProfile,
      store: _growthStore,
    );
    final screenTimeRepository = await ScreenTimeRepository.load(
      clock: _clock,
      boundary: DailyBoundary(regionalProfile),
      store: _screenTimeStore,
    );
    final entitlement = widget.entitlementReader != null
        ? await widget.entitlementReader!.current()
        : _entitlement;
    if (!mounted) return;
    setState(() {
      _curriculum = curriculum;
      _source = source;
      _growthRepository = growthRepository;
      _regionalProfile = regionalProfile;
      _screenTimeRepository = screenTimeRepository;
      _entitlement = entitlement;
    });
  }

  Future<void> _togglePremiumOrRefreshEntitlement() async {
    if (widget.entitlementReader != null) {
      final entitlement = await widget.entitlementReader!.current();
      if (mounted) setState(() => _entitlement = entitlement);
      return;
    }
    setState(() {
      _entitlement = Entitlement(
        unlockedSubjectIds: _entitlement.unlockedSubjectIds,
        isPremium: !_entitlement.isPremium,
      );
    });
  }

  Future<void> _runAgeGateFlow() async {
    await showAgeGateFlow(
      context,
      profile: _regionalProfile!,
      clock: _clock,
      consentStore: _consentStore,
    );
    final consent = await _consentStore.getConsent();
    if (!mounted) return;
    setState(() => _consent = consent);
  }

  Future<void> _toggleDailyReminder() async {
    if (_dailyReminderScheduledAt != null) {
      await _notificationScheduler.cancel(_dailyReminderId);
      setState(() => _dailyReminderScheduledAt = null);
      return;
    }
    final planner = DailyReminderPlanner(_regionalProfile!);
    final reminderAt = planner.reminderAt(_clock.now());
    await _notificationScheduler.schedule(
      id: _dailyReminderId,
      at: reminderAt,
      titleKey: 'dailyReminderTitle',
      bodyKey: 'dailyReminderBody',
    );
    setState(() => _dailyReminderScheduledAt = reminderAt);
  }

  ScreenTimeGuard get _screenTimeGuard {
    final profile = _regionalProfile!;
    final effectiveProfile = _screenTimeLimitDemoEnabled
        ? RegionalProfile(
            locale: profile.locale,
            ageOfConsent: profile.ageOfConsent,
            guardianConsentRequired: profile.guardianConsentRequired,
            dailyResetHour: profile.dailyResetHour,
            timeZone: profile.timeZone,
            // 結合確認用に短い制限（1分）を模擬する。
            screenTimeLimitMinutes: 1,
            profilingAdsAllowed: profile.profilingAdsAllowed,
          )
        : profile;
    return ScreenTimeGuard(effectiveProfile);
  }

  static const _stageVisual = <GrowthStage, (IconData, String)>{
    GrowthStage.egg: (Icons.egg_outlined, 'Ovo'),
    GrowthStage.baby: (Icons.child_care, 'Filhote'),
    GrowthStage.child: (Icons.pets, 'Jovem'),
    GrowthStage.adult: (Icons.auto_awesome, 'Adulto'),
  };

  static const _eixoVisual = <String, (IconData, Color)>{
    'numeros': (Icons.numbers, Colors.indigo),
    'algebra': (Icons.functions, Colors.deepPurple),
    'geometria': (Icons.change_history, Colors.teal),
    'grandezas': (Icons.straighten, Colors.orange),
    'probabilidade': (Icons.bar_chart, Colors.pink),
  };

  (IconData, Color) _visualForUnit(Unit unit) {
    for (final entry in _eixoVisual.entries) {
      if (unit.id.contains(entry.key)) return entry.value;
    }
    return (Icons.menu_book_outlined, Colors.blueGrey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final curriculum = _curriculum;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('小学コレ！ Matemática'),
        actions: [
          IconButton(
            key: const Key('premiumToggleButton'),
            tooltip: _entitlement.isPremium ? 'premium: ON' : 'premium: OFF',
            icon: Icon(
              _entitlement.isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
            ),
            onPressed: _togglePremiumOrRefreshEntitlement,
          ),
          IconButton(
            key: const Key('screenTimeLimitToggleButton'),
            tooltip: _screenTimeLimitDemoEnabled ? 'limit: 1min' : 'limit: OFF',
            icon: Icon(
              _screenTimeLimitDemoEnabled ? Icons.timer : Icons.timer_off_outlined,
            ),
            onPressed: () => setState(() {
              _screenTimeLimitDemoEnabled = !_screenTimeLimitDemoEnabled;
            }),
          ),
        ],
      ),
      body: curriculum == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _GrowthHeroCard(
                  key: const Key('growthStatusTile'),
                  stageIcon: _stageVisual[_growthRepository!.stage]!.$1,
                  stageLabel: _stageVisual[_growthRepository!.stage]!.$2,
                  coins: _growthRepository!.wallet.balance,
                ),
                const SizedBox(height: 12),
                _ScreenTimeCard(
                  key: const Key('screenTimeStatusTile'),
                  usedMinutes: _screenTimeRepository!.usedToday.inMinutes,
                  remainingMinutes: _screenTimeGuard
                      .remaining(_screenTimeRepository!.usedToday)
                      .inMinutes,
                ),
                _SectionLabel(label: 'Escolha uma unidade'),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final cardWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final unit
                            in curriculum.units.where((u) => u.templateIds.isNotEmpty))
                          SizedBox(
                            width: cardWidth,
                            height: 128,
                            child: _UnitCard(
                        unitKey: Key('unit_${unit.id}'),
                        label: unit.id,
                        grade: unit.grade,
                        icon: _visualForUnit(unit).$1,
                        color: _visualForUnit(unit).$2,
                        locked: !_entitlement.isUnlocked(unit.subjectId),
                        onTap: () async {
                          if (!_entitlement.isUnlocked(unit.subjectId)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                key: const Key('entitlementLockedSnackBar'),
                                content: Text(l10n.entitlementLockedMessage),
                              ),
                            );
                            return;
                          }
                          if (_screenTimeGuard.isOverLimit(_screenTimeRepository!.usedToday)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                key: const Key('screenTimeLimitSnackBar'),
                                content: Text(l10n.screenTimeLimitReached),
                              ),
                            );
                            return;
                          }
                          final openedAt = _clock.now();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuestionScreen(
                                unit: unit,
                                source: _source!,
                                progressStore: _progressStore,
                                clock: _clock,
                                questionCache: _questionCache,
                                growthRepository: _growthRepository!,
                              ),
                            ),
                          );
                          await _screenTimeRepository!
                              .addUsage(_clock.now().difference(openedAt));
                          // 出題画面でgrowth状態（stage/coins）が更新されている可能性があるため、
                          // ホームに戻った際に再描画する。
                          if (mounted) setState(() {});
                        },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                _SectionLabel(label: 'レポート・設定'),
                Card(
                  child: ListTile(
                    key: const Key('weeklyReportTile'),
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: Text(l10n.weeklyReportTile),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WeeklyReportScreen(
                          unitIds: curriculum.units.map((u) => u.id).toList(),
                          progressStore: _progressStore,
                          clock: _clock,
                          questionCache: _questionCache,
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('ageVerificationTile'),
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(l10n.ageVerificationTile),
                    subtitle: Text(
                      (_consent?.parentalConsentGiven ?? false)
                          ? l10n.consentStatusGiven
                          : l10n.consentStatusNotGiven,
                      key: const Key('consentStatusText'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _runAgeGateFlow,
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('dailyReminderTile'),
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(l10n.dailyReminderTile),
                    subtitle: Text(
                      _dailyReminderScheduledAt != null
                          ? l10n.dailyReminderScheduled(
                              _dailyReminderScheduledAt!.hour,
                              _dailyReminderScheduledAt!.minute,
                            )
                          : l10n.dailyReminderNotScheduled,
                      key: const Key('dailyReminderStatusText'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _toggleDailyReminder,
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('dataPrivacyTile'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.dataPrivacyTile),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DataPrivacyScreen(
                          consentStore: _consentStore,
                          progressStore: _progressStore,
                          onDataErased: () {
                            if (mounted) setState(() => _consent = null);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('guardianGateTile'),
                    leading: const Icon(Icons.shield_outlined),
                    title: Text(l10n.guardianGateTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final passed = await showGuardianGateDialog(context);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          key: const Key('guardianGateResultSnackBar'),
                          content: Text(passed ? 'guardian_gate_passed' : 'guardian_gate_failed'),
                        ),
                      );
                    },
                  ),
                ),
                ],
              ),
            ),
    );
  }
}

/// 成長段階とコインを大きく見せるヒーローカード。
class _GrowthHeroCard extends StatelessWidget {
  const _GrowthHeroCard({
    super.key,
    required this.stageIcon,
    required this.stageLabel,
    required this.coins,
  });

  final IconData stageIcon;
  final String stageLabel;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            foregroundColor: theme.colorScheme.primary,
            child: Icon(stageIcon, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 18, color: theme.colorScheme.onPrimary),
                    const SizedBox(width: 4),
                    Text(
                      '$coins moedas',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTimeCard extends StatelessWidget {
  const _ScreenTimeCard({
    super.key,
    required this.usedMinutes,
    required this.remainingMinutes,
  });

  final int usedMinutes;
  final int remainingMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: const Icon(Icons.schedule),
        ),
        title: Text(
          'screen time used: ${usedMinutes}min, remaining: ${remainingMinutes}min',
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: const Text('本日の学習時間の消化状況'),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unitKey,
    required this.label,
    required this.grade,
    required this.icon,
    required this.color,
    required this.locked,
    required this.onTap,
  });

  final Key unitKey;
  final String label;
  final int grade;
  final IconData icon;
  final Color color;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: unitKey,
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    child: Icon(icon, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text('grade $grade', style: theme.textTheme.bodySmall),
                ],
              ),
              if (locked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.lock,
                    key: const Key('lockIcon'),
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
