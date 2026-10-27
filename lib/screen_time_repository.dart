import 'package:shoukore_core_global/shoukore_core_global.dart';

/// 利用時間の計測自体はアプリ側の責務（ADR参照）。永続化は`ScreenTimeStore`
/// （既定実装は`DriftScreenTimeStore`、端末内drift）に委ねる。サンプルアプリでは
/// 他のStoreモジュール同様、結合テストで検証しやすい`InMemoryScreenTimeStore`を使う
/// （`ScreenTimeStore`の実装はいずれも
/// `test/screen_time_store_contract_test.dart`の契約テストで検証済み）。
class ScreenTimeRepository {
  ScreenTimeRepository._({
    required this.clock,
    required this.boundary,
    required ScreenTimeStore store,
    required ScreenTimeSnapshot snapshot,
  })  : _store = store,
        _snapshot = snapshot;

  /// `store`に保存済みの状態を読み込んで`ScreenTimeRepository`を構築する。
  /// ミッション日が変わっていれば利用時間を0にリセットする。
  static Future<ScreenTimeRepository> load({
    required Clock clock,
    required DailyBoundary boundary,
    required ScreenTimeStore store,
  }) async {
    var snapshot = await store.load();
    final today = boundary.currentMissionDay(clock);
    if (snapshot.day == null || !boundary.isSameMissionDay(snapshot.day!, today)) {
      snapshot = ScreenTimeSnapshot(usedTodayMinutes: 0, day: today);
    }
    return ScreenTimeRepository._(
      clock: clock,
      boundary: boundary,
      store: store,
      snapshot: snapshot,
    );
  }

  final Clock clock;
  final DailyBoundary boundary;

  final ScreenTimeStore _store;
  ScreenTimeSnapshot _snapshot;

  Duration get usedToday => Duration(minutes: _snapshot.usedTodayMinutes);

  /// 出題画面を開いていた時間を積算する。ミッション日が変わっていればリセットする。
  Future<void> addUsage(Duration elapsed) async {
    final today = boundary.currentMissionDay(clock);
    final base = (_snapshot.day == null || !boundary.isSameMissionDay(_snapshot.day!, today))
        ? 0
        : _snapshot.usedTodayMinutes;
    _snapshot = ScreenTimeSnapshot(
      usedTodayMinutes: base + elapsed.inMinutes,
      day: today,
    );
    await _store.save(_snapshot);
  }
}
