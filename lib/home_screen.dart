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
  const HomeScreen({super.key, required this.onLocaleChanged});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _repository = CurriculumRepository();
  static const _clock = SystemClock();

  Locale? _loadedLocale;
  CurriculumData? _curriculum;
  ArithmeticQuestionSource? _source;
  GrowthRepository? _growthRepository;
  RegionalProfile? _regionalProfile;
  ScreenTimeRepository? _screenTimeRepository;
  final ScreenTimeStore _screenTimeStore = InMemoryScreenTimeStore();

  // pt_BRの既定ではscreenTimeLimitMinutesが0（無制限）のため、結合確認用に
  // 保護者が制限を設定した状態を模擬するトグルを用意する。
  bool _screenTimeLimitDemoEnabled = false;

  // progressStoreは単元ツリーのロケールに関わらず端末内に1つだけ持つ
  // （学習記録はロケール切替の影響を受けない）。drift実装自体はコア側のテストで
  // 検証済みのため、サンプルアプリではUI結合確認に専念するInMemory実装を使う。
  final ProgressStore _progressStore = InMemoryProgressStore();
  final GrowthStore _growthStore = InMemoryGrowthStore();
  final QuestionCache _questionCache = QuestionCache();
  final ConsentStore _consentStore = InMemoryConsentStore();
  ConsentRecord? _consent;

  // 通知のスケジューリングはアプリ側の責務（プッシュ(FCM)は使わない設計）。
  // 実機通知アダプタ(LocalNotificationScheduler)はプラットフォームプラグイン登録に
  // 依存しテスト環境では検証できないため（ADR参照）、サンプルアプリでは
  // InMemoryNotificationSchedulerでスケジュール状態のUI結合確認に専念する。
  final NotificationScheduler _notificationScheduler = InMemoryNotificationScheduler();
  static const _dailyReminderId = 'daily_reminder';
  DateTime? _dailyReminderScheduledAt;

  // 課金状態はアプリ側の責務（ADR参照）。コアは`Entitlement`を読むだけなので、
  // サンプルアプリでは購入フローの代わりにpremiumトグルで模擬する。
  Entitlement _entitlement = const Entitlement(unlockedSubjectIds: {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_loadedLocale != locale) {
      _loadedLocale = locale;
      _load(locale);
    }
  }

  Future<void> _load(Locale locale) async {
    final curriculum = await _repository.loadCurriculum(locale);
    final localeKey = _repository.localeKey(locale);
    final source = ArithmeticQuestionSource(
      unitsByLocale: {localeKey: curriculum.units},
      templates: curriculum.templates,
    );
    // growth（コイン・成長段階）は端末単位の進捗であり、学習記録と同様に
    // ロケール切替の影響を受けない。既に生成済みなら使い回す。
    GrowthRepository? growthRepository = _growthRepository;
    RegionalProfile? regionalProfile = _regionalProfile;
    ScreenTimeRepository? screenTimeRepository = _screenTimeRepository;
    if (growthRepository == null || regionalProfile == null || screenTimeRepository == null) {
      regionalProfile ??= await _repository.loadRegionalProfile(locale);
      growthRepository ??= await GrowthRepository.load(
        clock: _clock,
        profile: regionalProfile,
        store: _growthStore,
      );
      screenTimeRepository ??= await ScreenTimeRepository.load(
        clock: _clock,
        boundary: DailyBoundary(regionalProfile),
        store: _screenTimeStore,
      );
    }
    if (!mounted) return;
    setState(() {
      _curriculum = curriculum;
      _source = source;
      _growthRepository = growthRepository;
      _regionalProfile = regionalProfile;
      _screenTimeRepository = screenTimeRepository;
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
          TextButton(
            key: const Key('localePtBrButton'),
            onPressed: () => widget.onLocaleChanged(const Locale('pt', 'BR')),
            child: const Text('PT-BR', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            key: const Key('premiumToggleButton'),
            onPressed: () => setState(() {
              _entitlement = Entitlement(
                unlockedSubjectIds: _entitlement.unlockedSubjectIds,
                isPremium: !_entitlement.isPremium,
              );
            }),
            child: Text(
              _entitlement.isPremium ? 'premium: ON' : 'premium: OFF',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            key: const Key('screenTimeLimitToggleButton'),
            onPressed: () => setState(() {
              _screenTimeLimitDemoEnabled = !_screenTimeLimitDemoEnabled;
            }),
            child: Text(
              _screenTimeLimitDemoEnabled ? 'limit: 1min' : 'limit: OFF',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: curriculum == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _SectionLabel(label: '今日のステータス'),
                Card(
                  child: ListTile(
                    key: const Key('growthStatusTile'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.auto_awesome),
                    ),
                    title: Text(
                      'stage: ${_growthRepository!.stage.name}  /  coins: ${_growthRepository!.wallet.balance}',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: const Text('成長段階とコインの状態'),
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('screenTimeStatusTile'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      child: const Icon(Icons.schedule),
                    ),
                    title: Text(
                      'screen time used: ${_screenTimeRepository!.usedToday.inMinutes}min, '
                      'remaining: ${_screenTimeGuard.remaining(_screenTimeRepository!.usedToday).inMinutes}min',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: const Text('本日の学習時間の消化状況'),
                  ),
                ),
                _SectionLabel(label: '単元を選ぶ'),
                for (final unit in curriculum.units.where((u) => u.templateIds.isNotEmpty))
                  Card(
                    child: ListTile(
                      key: Key('unit_${unit.id}'),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.tertiaryContainer,
                        foregroundColor: theme.colorScheme.onTertiaryContainer,
                        child: const Icon(Icons.menu_book_outlined),
                      ),
                      title: Text(unit.id, style: theme.textTheme.titleMedium),
                      subtitle: Text('grade ${unit.grade}'),
                      trailing: _entitlement.isUnlocked(unit.subjectId)
                          ? const Icon(Icons.chevron_right)
                          : Icon(
                              Icons.lock,
                              key: const Key('lockIcon'),
                              color: theme.colorScheme.outline,
                            ),
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
                      await _screenTimeRepository!.addUsage(_clock.now().difference(openedAt));
                      // 出題画面でgrowth状態（stage/coins）が更新されている可能性があるため、
                      // ホームに戻った際に再描画する。
                      if (mounted) setState(() {});
                      },
                    ),
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
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
