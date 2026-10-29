import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
// example独自の軽量InMemoryProgressStoreを使うため、コアが同名で公開している
// 実装（テスト・プロトタイピング用途向け）を隠す。
import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

import 'age_gate_dialog.dart';
import 'badge_collection_screen.dart';
import 'character_collection_repository.dart';
import 'character_definition.dart';
import 'collection_screen.dart';
import 'cross_promo_section.dart';
import 'curriculum_repository.dart';
import 'data_privacy_screen.dart';
import 'equipped_items.dart';
import 'family_challenge_unit_picker_screen.dart';
import 'game_mode_unit_picker_screen.dart';
import 'growth_repository.dart';
import 'guardian_dialog.dart';
import 'in_memory_progress_store.dart';
import 'l10n/app_localizations.dart';
import 'math_guide_screen.dart';
import 'question_cache.dart';
import 'question_screen.dart';
import 'screen_time_repository.dart';
import 'shop_screen.dart';
import 'src/question/arithmetic_question_source.dart';
import 'src/question/composite_question_source.dart';
import 'src/question/curriculum_loader.dart';
import 'src/question/geometry_question_source.dart';
import 'src/question/measurement_question_source.dart';
import 'src/question/sequence_question_source.dart';
import 'src/question/statistics_question_source.dart';
import 'unit_name_resolver.dart';
import 'weekly_challenge_repository.dart';
import 'weekly_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.entitlementReader,
    this.consentStore,
    this.displayLocale,
    this.onDisplayLocaleChanged,
  });

  /// RevenueCat APIキー未設定（開発中・CI）の場合はnullのままにする。
  /// nullの場合、premiumToggleButtonは課金状態を模擬するデバッグ用トグルの
  /// ままになる。
  final EntitlementReader? entitlementReader;

  /// オンボーディングの年齢確認と同じ同意記録を共有するため、アプリ直下
  /// から渡す。未指定時は自前で生成する（単体テスト等での単独利用向け）。
  final ConsentStore? consentStore;

  /// 現在の表示言語(CLAUDE.md共通要件「第二言語に英語も選択できる」対応)。
  /// アプリ直下(main.dart)のMaterialApp.localeと同じ値を渡す。
  /// BNCCカリキュラム自体はpt_BR固定のため、これは画面表示文言のみに影響する。
  final Locale? displayLocale;
  final ValueChanged<Locale>? onDisplayLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _repository = CurriculumRepository();
  static const _clock = SystemClock();
  static const _locale = Locale('pt', 'BR');

  CurriculumData? _curriculum;
  QuestionSource? _source;
  GrowthRepository? _growthRepository;
  RegionalProfile? _regionalProfile;
  ScreenTimeRepository? _screenTimeRepository;
  final ScreenTimeStore _screenTimeStore = InMemoryScreenTimeStore();

  // pt_BRの既定ではscreenTimeLimitMinutesが0（無制限）のため、結合確認用に
  // 保護者が制限を設定した状態を模擬するトグルを用意する。
  bool _screenTimeLimitDemoEnabled = false;

  final ProgressStore _progressStore = InMemoryProgressStore();
  final GrowthStore _growthStore = InMemoryGrowthStore();
  final CharacterCollectionStore _characterCollectionStore = InMemoryCharacterCollectionStore();
  CharacterCollectionSnapshot _characterSnapshot = CharacterCollectionSnapshot.initial;
  late final _characterCollectionRepository = CharacterCollectionRepository(
    progressStore: _progressStore,
    collectionStore: _characterCollectionStore,
  );
  final QuestionCache _questionCache = QuestionCache();
  late final ConsentStore _consentStore = widget.consentStore ?? InMemoryConsentStore();
  ConsentRecord? _consent;

  final NotificationScheduler _notificationScheduler = InMemoryNotificationScheduler();
  static const _dailyReminderId = 'daily_reminder';
  DateTime? _dailyReminderScheduledAt;

  // 課金状態はアプリ側の責務（ADR参照）。実際の購入フローはストア申請時に実装し、
  // 現時点ではpremiumトグルで模擬する。
  Entitlement _entitlement = const Entitlement(unlockedSubjectIds: {});

  /// 購読前でも試せるように、1º ano(1年生)の単元は無料で開放する。
  /// 2º ano 以降は購読(またはお試し期間)で開放される。
  static const _freeGrade = 1;

  bool _isUnitUnlocked(Unit unit) =>
      unit.grade <= _freeGrade || _entitlement.isUnlocked(unit.subjectId);

  // 無限に出題される中でも「マスターした」ことが分かるよう、単元ごとに
  // 直近10問・正答率90%以上をマスター済みと判定する(コア側の判定ロジックを利用)。
  static const _masteryEligibility = UnitMasteryBadgeEligibility();
  Set<String> _masteredUnitIds = {};

  final WeeklyChallengeStore _weeklyChallengeStore = InMemoryWeeklyChallengeStore();
  WeeklyChallengeRepository? _weeklyChallengeRepository;

  final InventoryStore _inventoryStore = InMemoryInventoryStore();
  InventorySnapshot _inventorySnapshot = InventorySnapshot.initial;
  final EquippedItemsStore _equippedItemsStore = InMemoryEquippedItemsStore();
  EquippedItems _equippedItems = EquippedItems.initial;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final curriculum = await _repository.loadCurriculum(_locale);
    final localeKey = _repository.localeKey(_locale);
    final unitsByLocale = {localeKey: curriculum.units};
    final source = CompositeQuestionSource(
      arithmeticSource: ArithmeticQuestionSource(
        unitsByLocale: unitsByLocale,
        templates: curriculum.templates,
      ),
      geometrySource: GeometryQuestionSource(
        unitsByLocale: unitsByLocale,
        templates: curriculum.shapeTemplates,
      ),
      measurementSource: MeasurementQuestionSource(
        unitsByLocale: unitsByLocale,
        templates: curriculum.unitConversionTemplates,
      ),
      sequenceSource: SequenceQuestionSource(
        unitsByLocale: unitsByLocale,
        templates: curriculum.sequenceTemplates,
      ),
      statisticsSource: StatisticsQuestionSource(
        unitsByLocale: unitsByLocale,
        templates: curriculum.dataSetTemplates,
      ),
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
    final characterResult = await _characterCollectionRepository.refresh(curriculum.units);
    final consent = await _consentStore.getConsent();
    final weeklyChallengeRepository = await WeeklyChallengeRepository.load(
      clock: _clock,
      store: _weeklyChallengeStore,
    );
    final inventorySnapshot = await _inventoryStore.load();
    final equippedItems = await _equippedItemsStore.load();
    if (!mounted) return;
    setState(() {
      _curriculum = curriculum;
      _source = source;
      _growthRepository = growthRepository;
      _regionalProfile = regionalProfile;
      _screenTimeRepository = screenTimeRepository;
      _entitlement = entitlement;
      _characterSnapshot = characterResult.snapshot;
      _consent = consent;
      _weeklyChallengeRepository = weeklyChallengeRepository;
      _inventorySnapshot = inventorySnapshot;
      _equippedItems = equippedItems;
    });
    await _refreshMasteredUnits(curriculum.units);
  }

  /// 単元ごとのマスター判定を更新する。新たにマスターした単元があれば
  /// お祝いのSnackBarを表示し、「やった感」を実感できるようにする。
  Future<void> _refreshMasteredUnits(List<Unit> units) async {
    final masteredIds = <String>{};
    for (final unit in units) {
      final attempts = await _progressStore.getAttempts(unit.id);
      if (_masteryEligibility.isMastered(attempts)) {
        masteredIds.add(unit.id);
      }
    }
    final newlyMastered = masteredIds.difference(_masteredUnitIds);
    if (!mounted) return;
    setState(() => _masteredUnitIds = masteredIds);
    if (newlyMastered.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('unitMasteredSnackBar'),
          content: Text(AppLocalizations.of(context)!.unitMasteredMessage(newlyMastered.first)),
        ),
      );
    }
  }

  /// 新規所持・レベルアップしたキャラがいれば、お祝いのSnackBarを表示する。
  void _showCharacterCollectionChanges(CharacterCollectionRefreshResult result) {
    if (!result.hasChanges || !mounted) return;
    final messages = <String>[
      for (final id in result.newlyOwned)
        'Você conheceu ${_characterById(id).name}!',
      for (final entry in result.leveledUp.entries)
        if (!result.newlyOwned.contains(entry.key))
          '${_characterById(entry.key).name} evoluiu para ${characterLevelLabels[entry.value]}!',
    ];
    for (final message in messages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(key: const Key('characterCollectionChangeSnackBar'), content: Text(message)),
      );
    }
  }

  CharacterDefinition _characterById(String id) =>
      characterDefinitions.firstWhere((def) => def.id == id);

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

  static const _supportedDisplayLocales = [Locale('pt', 'BR'), Locale('en')];

  // 言語名はその言語自身の表記(自称)で示す（訳さない）のが一般的な作法。
  String _localeDisplayName(Locale? locale) {
    if (locale?.languageCode == 'en') return 'English';
    return 'Português (Brasil)';
  }

  Future<void> _showLanguagePicker(BuildContext context, AppLocalizations l10n) async {
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.languageDialogTitle),
        children: [
          for (final locale in _supportedDisplayLocales)
            SimpleDialogOption(
              key: Key('languageOption_${locale.languageCode}'),
              onPressed: () => Navigator.of(context).pop(locale),
              child: Text(_localeDisplayName(locale)),
            ),
        ],
      ),
    );
    if (selected != null) widget.onDisplayLocaleChanged?.call(selected);
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

  // eixo(分野)ごとに別々の色相を使うと、算数という1教科のまとまりが
  // 見えにくい。教科色(アプリのテーマシード色=算数の教科色)を基準に、
  // 明度だけを変えたトーンのパレットに統一する。
  static const _eixoIcons = <String, IconData>{
    'numeros': Icons.numbers,
    'algebra': Icons.functions,
    'geometria': Icons.change_history,
    'grandezas': Icons.straighten,
    'probabilidade': Icons.bar_chart,
  };
  static const _eixoOrder = ['numeros', 'algebra', 'geometria', 'grandezas', 'probabilidade'];

  (IconData, Color) _visualForUnit(Unit unit, Color subjectColor) {
    final hsl = HSLColor.fromColor(subjectColor);
    for (var i = 0; i < _eixoOrder.length; i++) {
      final key = _eixoOrder[i];
      if (unit.id.contains(key)) {
        final lightness = 0.32 + (i * 0.11);
        return (_eixoIcons[key]!, hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor());
      }
    }
    return (Icons.menu_book_outlined, subjectColor);
  }

  /// 単元タップ時の共通処理（単元カード・クイックスタートカードの両方で使う）。
  Future<void> _openUnit(BuildContext context, AppLocalizations l10n, Unit unit) async {
    if (!_isUnitUnlocked(unit)) {
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
    final curriculum = _curriculum!;
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
          weeklyChallengeRepository: _weeklyChallengeRepository,
          notificationScheduler: _notificationScheduler,
        ),
      ),
    );
    await _screenTimeRepository!.addUsage(_clock.now().difference(openedAt));
    final characterResult = await _characterCollectionRepository.refresh(curriculum.units);
    // 出題画面でgrowth状態（stage/coins）・キャラコレクション・ウィークリー
    // チャレンジ進捗が更新されている可能性があるため、ホームに戻った際に
    // 再描画する。
    if (mounted) {
      setState(() => _characterSnapshot = characterResult.snapshot);
      _showCharacterCollectionChanges(characterResult);
    }
    await _refreshMasteredUnits(curriculum.units);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final curriculum = _curriculum;
    final theme = Theme.of(context);
    final totalUnitsWithContent = curriculum == null
        ? 0
        : curriculum.units.where((u) => u.templateIds.isNotEmpty).length;
    final nextUnit = curriculum == null
        ? null
        : curriculum.units.where((u) => u.templateIds.isNotEmpty).firstWhere(
              (u) =>
                  _isUnitUnlocked(u) &&
                  !_masteredUnitIds.contains(u.id),
              orElse: () => curriculum.units.firstWhere((u) => u.templateIds.isNotEmpty),
            );
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: curriculum == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 96,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  title: Text(l10n.homeTitle),
                  actions: [
                    IconButton(
                      key: const Key('premiumToggleButton'),
                      tooltip: _entitlement.isPremium ? 'premium: ON' : 'premium: OFF',
                      icon: Icon(
                        _entitlement.isPremium
                            ? Icons.workspace_premium
                            : Icons.workspace_premium_outlined,
                      ),
                      onPressed: _togglePremiumOrRefreshEntitlement,
                    ),
                    // 開発用(制限1分の模擬)。ストアに出るリリースビルドでは隠す。
                    if (!kReleaseMode)
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
                SliverToBoxAdapter(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // 「ゲームで学ぶ」はストア訴求の目玉機能のため、ホーム画面最上部に
                // 目立つバナーとして配置する。
                Material(
                  key: const Key('gameModeTile'),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameModeUnitPickerScreen(
                          units: curriculum.units,
                          onUnitTap: (context, unit) async {
                            Navigator.of(context).pop();
                            await _openUnit(context, l10n, unit);
                          },
                          lockedUnitIds: {
                            for (final unit in curriculum.units)
                              if (!_isUnitUnlocked(unit)) unit.id,
                          },
                          masteredUnitIds: _masteredUnitIds,
                        ),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_esports,
                              size: 40,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.gameModeTile,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.gameModeTileSubtitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _StatsRow(
                  key: const Key('growthStatusTile'),
                  streakDays: _growthRepository!.streak.currentStreakDays,
                  coins: _growthRepository!.wallet.balance,
                  clearedUnits: _masteredUnitIds.length,
                  totalUnits: totalUnitsWithContent,
                ),
                const SizedBox(height: 12),
                if (_weeklyChallengeRepository != null)
                  _WeeklyChallengeCard(
                    key: const Key('weeklyChallengeTile'),
                    completedCount: _weeklyChallengeRepository!.completedCount,
                    totalTarget: WeeklyChallengeRepository.totalTarget,
                  ),
                const SizedBox(height: 12),
                if (nextUnit != null)
                  _QuickStartCard(
                    key: const Key('quickStartTile'),
                    label: resolveUnitName(l10n, nextUnit.id),
                    onTap: () => _openUnit(context, l10n, nextUnit),
                  ),
                const SizedBox(height: 12),
                _ScreenTimeCard(
                  key: const Key('screenTimeStatusTile'),
                  usedMinutes: _screenTimeRepository!.usedToday.inMinutes,
                  remainingMinutes: _screenTimeGuard.isLimited
                      ? _screenTimeGuard
                          .remaining(_screenTimeRepository!.usedToday)
                          .inMinutes
                      : null,
                ),
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: ListTile(
                    key: const Key('familyChallengeTile'),
                    leading: Icon(
                      Icons.diversity_3,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    title: Text(
                      l10n.familyChallengeTile,
                      style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                    ),
                    subtitle: Text(
                      l10n.familyChallengeTileSubtitle,
                      style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    onTap: !_entitlement.isUnlocked(curriculum.units.first.subjectId)
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.entitlementLockedMessage)),
                            )
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FamilyChallengeUnitPickerScreen(
                                  units: curriculum.units,
                                  source: _source!,
                                  progressStore: _progressStore,
                                  growthRepository: _growthRepository!,
                                  clock: _clock,
                                  questionCache: _questionCache,
                                ),
                              ),
                            ),
                  ),
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
                            height: 144,
                            child: _UnitCard(
                        unitKey: Key('unit_${unit.id}'),
                        label: resolveUnitName(l10n, unit.id),
                        grade: unit.grade,
                        icon: _visualForUnit(unit, theme.colorScheme.primary).$1,
                        color: _visualForUnit(unit, theme.colorScheme.primary).$2,
                        locked: !_isUnitUnlocked(unit),
                        mastered: _masteredUnitIds.contains(unit.id),
                        onTap: () => _openUnit(context, l10n, unit),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                _SectionLabel(label: 'Coleção'),
                Card(
                  child: ListTile(
                    key: const Key('collectionTile'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.auto_awesome),
                    ),
                    title: const Text('Minha Coleção'),
                    subtitle: Text(
                      '${_characterSnapshot.ownedCount} / ${characterDefinitions.length} personagens',
                      key: const Key('collectionTileProgressText'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CollectionScreen(
                          snapshot: _characterSnapshot,
                          equippedItems: _equippedItems,
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('shopTile'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      child: const Icon(Icons.storefront),
                    ),
                    title: Text(l10n.shopTile),
                    subtitle: Text(l10n.shopTileSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopScreen(
                          growthRepository: _growthRepository!,
                          inventoryStore: _inventoryStore,
                          inventory: _inventorySnapshot,
                          onInventoryChanged: (snapshot) =>
                              setState(() => _inventorySnapshot = snapshot),
                          equippedItemsStore: _equippedItemsStore,
                          equippedItems: _equippedItems,
                          onEquippedItemsChanged: (items) =>
                              setState(() => _equippedItems = items),
                        ),
                      ),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('badgeCollectionTile'),
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withValues(alpha: 0.2),
                      foregroundColor: Colors.amber[800],
                      child: const Icon(Icons.emoji_events),
                    ),
                    title: const Text('Minhas Medalhas'),
                    subtitle: Text(
                      '${_masteredUnitIds.length} / '
                      '${curriculum.units.where((u) => u.templateIds.isNotEmpty).length} '
                      'unidades dominadas',
                      key: const Key('badgeCollectionTileProgressText'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BadgeCollectionScreen(
                          units: curriculum.units,
                          masteredUnitIds: _masteredUnitIds,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_masteredUnitIds.isNotEmpty)
                  _RecentBadgesPreview(
                    key: const Key('recentBadgesPreview'),
                    units: curriculum.units
                        .where((u) => _masteredUnitIds.contains(u.id))
                        .take(4)
                        .toList(),
                    labelFor: (unit) => resolveUnitName(l10n, unit.id),
                    visualFor: (unit) => _visualForUnit(unit, theme.colorScheme.primary),
                  ),
                Card(
                  child: ListTile(
                    key: const Key('mathGuideTile'),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      foregroundColor: theme.colorScheme.onSecondaryContainer,
                      child: const Icon(Icons.menu_book),
                    ),
                    title: Text(l10n.mathGuideTile),
                    subtitle: Text(l10n.mathGuideTileSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MathGuideScreen()),
                    ),
                  ),
                ),
                _SectionLabel(label: 'Mais da Colecinho!'),
                const CrossPromoSection(),
                if (widget.onDisplayLocaleChanged != null) ...[
                  _SectionLabel(label: l10n.settingsGeneralSection),
                  Card(
                    child: ListTile(
                      key: const Key('languageTile'),
                      leading: const Icon(Icons.language_outlined),
                      title: Text(l10n.languageTile),
                      subtitle: Text(_localeDisplayName(widget.displayLocale)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguagePicker(context, l10n),
                    ),
                  ),
                ],
                _SectionLabel(label: l10n.settingsNotificationsSection),
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
                _SectionLabel(label: l10n.settingsParentsSection),
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
                    key: const Key('dataPrivacyTile'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.dataPrivacyTile),
                    trailing: const Icon(Icons.chevron_right),
                    // 同意撤回・全データ削除という不可逆な操作に進めるため、
                    // 児童が誤って（または意図的に）開けないよう保護者ゲート
                    // で一度確認する。
                    onTap: () async {
                      final passed = await showGuardianGateDialog(context);
                      if (!passed || !context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DataPrivacyScreen(
                            consentStore: _consentStore,
                            progressStore: _progressStore,
                            onDataErased: () {
                              if (mounted) setState(() => _consent = null);
                            },
                          ),
                        ),
                      );
                    },
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
                          content: Text(
                            passed
                                ? l10n.guardianGatePassedMessage
                                : l10n.guardianGateFailedMessage,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                    ],
                  ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// れんぞく・コイン・クリア数を横並びでコンパクトに見せる統計カード行。
/// JP版の「最近獲得したバッジ」プレビューに相当する、マスター済み単元の
/// 小さいプレビュー行(最大4枚)。全件はbadgeCollectionTileから見られる。
class _RecentBadgesPreview extends StatelessWidget {
  const _RecentBadgesPreview({
    super.key,
    required this.units,
    required this.labelFor,
    required this.visualFor,
  });

  final List<Unit> units;
  final String Function(Unit) labelFor;
  final (IconData, Color) Function(Unit) visualFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (final unit in units)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  key: Key('recentBadge_${unit.id}'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: visualFor(unit).$2.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events, size: 20, color: Colors.amber[800]),
                      const SizedBox(height: 4),
                      Text(
                        labelFor(unit),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    super.key,
    required this.streakDays,
    required this.coins,
    required this.clearedUnits,
    required this.totalUnits,
  });

  final int streakDays;
  final int coins;
  final int clearedUnits;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    // JP版は統計カードごとに無関係な3色相(赤/黄/緑)を使っているが、
    // BR版は単元カードと同じ方針(アプリの教科色=テーマシード色に統一)に
    // 合わせ、Material3が1つのシード色から生成する3つのトナルロール
    // (primary/secondary/tertiary)で区別する。
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _StatCard(
          icon: Icons.local_fire_department,
          value: '$streakDays dias',
          label: 'Sequência',
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.monetization_on,
          value: '$coins',
          label: 'Moedas',
          color: colorScheme.secondary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.emoji_events,
          value: '$clearedUnits/$totalUnits',
          label: 'Dominadas',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// JP版の「ウィークリーチャレンジ」に相当する、今週あと何問正解すれば
/// 達成できるかを示す短期目標カード。
class _WeeklyChallengeCard extends StatelessWidget {
  const _WeeklyChallengeCard({
    super.key,
    required this.completedCount,
    required this.totalTarget,
  });

  final int completedCount;
  final int totalTarget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isComplete = completedCount >= totalTarget;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, size: 32, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weeklyChallengeTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isComplete
                      ? l10n.weeklyChallengeCompleteMessage
                      : l10n.weeklyChallengeProgress(completedCount, totalTarget),
                  key: const Key('weeklyChallengeProgressText'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (completedCount / totalTarget).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// JP版の「今日の算数をはじめよう！」に相当する、次に挑戦する単元への
/// クイックスタートCTAカード。
class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill, size: 36, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vamos praticar matemática hoje!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: theme.colorScheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenTimeCard extends StatelessWidget {
  const _ScreenTimeCard({
    super.key,
    required this.usedMinutes,
    this.remainingMinutes,
  });

  final int usedMinutes;
  /// 制限なしのときは null。
  final int? remainingMinutes;

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
          remainingMinutes == null
              ? AppLocalizations.of(context)!.screenTimeUsedNoLimit(usedMinutes)
              : AppLocalizations.of(context)!.screenTimeUsed(usedMinutes, remainingMinutes!),
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(AppLocalizations.of(context)!.screenTimeSubtitle),
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
    required this.mastered,
    required this.onTap,
  });

  final Key unitKey;
  final String label;
  final int grade;
  final IconData icon;
  final Color color;
  final bool locked;
  final bool mastered;
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
        child: Container(
          decoration: mastered
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 2),
                )
              : null,
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
                  Text(AppLocalizations.of(context)!.unitGradeLabel(grade), style: theme.textTheme.bodySmall),
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
              if (mastered)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(
                    Icons.emoji_events,
                    key: const Key('masteredIcon'),
                    size: 18,
                    color: Colors.amber[800],
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
