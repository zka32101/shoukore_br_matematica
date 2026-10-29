import 'package:shoukore_core_global/shoukore_core_global.dart';

/// growthモジュール（`DailyMissionRules`/`CoinWallet`/`GrowthStageCalculator`）は
/// いずれも純関数のみを提供し、永続化先を規定しない。永続化は`GrowthStore`
/// （既定実装は`DriftGrowthStore`、端末内drift）に委ねる。サンプルアプリでは
/// `ProgressStore`実装と同様、結合テストで検証しやすい`InMemoryGrowthStore`を
/// 使う（`GrowthStore`の実装はいずれも
/// `test/growth_store_contract_test.dart`の契約テストで検証済み）。
class GrowthRepository {
  GrowthRepository._({
    required this.clock,
    required this.profile,
    required GrowthStore store,
    required GrowthSnapshot snapshot,
    this.missionRules = const DailyMissionRules(),
    this.stageCalculator = const GrowthStageCalculator(),
  })  : _store = store,
        _snapshot = snapshot,
        boundary = DailyBoundary(profile);

  /// `store`に保存済みの状態を読み込んで`GrowthRepository`を構築する。
  static Future<GrowthRepository> load({
    required Clock clock,
    required RegionalProfile profile,
    required GrowthStore store,
    DailyMissionRules missionRules = const DailyMissionRules(),
    GrowthStageCalculator stageCalculator = const GrowthStageCalculator(),
  }) async {
    final snapshot = await store.load();
    return GrowthRepository._(
      clock: clock,
      profile: profile,
      store: store,
      snapshot: snapshot,
      missionRules: missionRules,
      stageCalculator: stageCalculator,
    );
  }

  final Clock clock;
  final RegionalProfile profile;
  final DailyMissionRules missionRules;
  final GrowthStageCalculator stageCalculator;
  final DailyBoundary boundary;

  final GrowthStore _store;
  GrowthSnapshot _snapshot;

  DailyMissionState get missionState => _snapshot.missionDay == null
      ? DailyMissionState(missionDay: boundary.currentMissionDay(clock))
      : DailyMissionState(
          missionDay: _snapshot.missionDay!,
          completedCount: _snapshot.missionCompletedCount,
          rewardClaimed: _snapshot.missionRewardClaimed,
        );
  CoinWallet get wallet => CoinWallet(balance: _snapshot.coinBalance);
  GrowthStage get stage => stageCalculator.stageFor(_snapshot.totalCorrectAnswers);
  LearningStreak get streak => LearningStreak(
        currentStreakDays: _snapshot.currentStreakDays,
        lastStudiedDay: _snapshot.lastStudiedDay,
      );

  /// 問題に回答するたびに呼ぶ（正誤を問わない）。学習ストリークを更新する。
  Future<void> recordStudyActivity() async {
    final nextStreak = streak.recordStudy(now: clock.now(), boundary: boundary);
    _snapshot = GrowthSnapshot(
      totalCorrectAnswers: _snapshot.totalCorrectAnswers,
      coinBalance: _snapshot.coinBalance,
      missionDay: _snapshot.missionDay,
      missionCompletedCount: _snapshot.missionCompletedCount,
      missionRewardClaimed: _snapshot.missionRewardClaimed,
      currentStreakDays: nextStreak.currentStreakDays,
      lastStudiedDay: nextStreak.lastStudiedDay,
    );
    await _store.save(_snapshot);
  }

  /// 1問正解するたびに呼ぶ。ミッション進捗を進め、目標達成していれば報酬を自動付与する。
  Future<void> recordCorrectAnswer() async {
    final nextMissionState = missionRules.recordCompletion(
      previous: missionState,
      now: clock.now(),
      boundary: boundary,
    );
    var wallet = this.wallet;
    var nextState = nextMissionState;
    if (missionRules.isRewardEligible(nextState)) {
      wallet = wallet.earn(missionRules.rewardCoins);
      nextState = missionRules.claimReward(nextState);
    }

    _snapshot = GrowthSnapshot(
      totalCorrectAnswers: _snapshot.totalCorrectAnswers + 1,
      coinBalance: wallet.balance,
      missionDay: nextState.missionDay,
      missionCompletedCount: nextState.completedCount,
      missionRewardClaimed: nextState.rewardClaimed,
      currentStreakDays: _snapshot.currentStreakDays,
      lastStudiedDay: _snapshot.lastStudiedDay,
    );
    await _store.save(_snapshot);
  }

  /// 「解説を読む」など、正誤判定を伴わない学習行動に対する少額ボーナス
  /// コインを付与する(デイリーミッション報酬とは別枠。問題を解くこと
  /// 自体に加えて、解説を読み返す行動そのものも後押しするための仕組み)。
  Future<void> earnBonusCoins(int amount) async {
    final nextWallet = wallet.earn(amount);
    _snapshot = GrowthSnapshot(
      totalCorrectAnswers: _snapshot.totalCorrectAnswers,
      coinBalance: nextWallet.balance,
      missionDay: _snapshot.missionDay,
      missionCompletedCount: _snapshot.missionCompletedCount,
      missionRewardClaimed: _snapshot.missionRewardClaimed,
      currentStreakDays: _snapshot.currentStreakDays,
      lastStudiedDay: _snapshot.lastStudiedDay,
    );
    await _store.save(_snapshot);
  }

  /// ショップでの購入時に呼ぶ。コイン残高を[newWallet]の値に更新する
  /// (実際の価格判定・差し引きはコア側の`InventoryManager.purchase`が行う)。
  Future<void> applyWallet(CoinWallet newWallet) async {
    _snapshot = GrowthSnapshot(
      totalCorrectAnswers: _snapshot.totalCorrectAnswers,
      coinBalance: newWallet.balance,
      missionDay: _snapshot.missionDay,
      missionCompletedCount: _snapshot.missionCompletedCount,
      missionRewardClaimed: _snapshot.missionRewardClaimed,
      currentStreakDays: _snapshot.currentStreakDays,
      lastStudiedDay: _snapshot.lastStudiedDay,
    );
    await _store.save(_snapshot);
  }
}
