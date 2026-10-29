import 'package:shoukore_core_global/shoukore_core_global.dart';

/// JP版(sansu-kore)の「ウィークリーチャレンジ」に相当する、今週あと何問
/// 正解すれば達成できるかを示す短期目標。デイリーのストリークだけでは
/// 「今日の分は終わった後にもう一度開く理由」が薄いため、週単位の目標を
/// 追加して定着率を上げる狙い。コアは数値のみ扱う方針(ADR参照)に合わせ、
/// アプリ側だけで完結する軽量な仕組みとして実装する(core変更なし)。
class WeeklyChallengeSnapshot {
  const WeeklyChallengeSnapshot({
    required this.weekStart,
    required this.completedCount,
  });

  static const initial = WeeklyChallengeSnapshot(weekStart: null, completedCount: 0);

  /// 今週の開始日(月曜、日付のみ)。未保存ならnull。
  final DateTime? weekStart;
  final int completedCount;
}

abstract class WeeklyChallengeStore {
  Future<WeeklyChallengeSnapshot> load();
  Future<void> save(WeeklyChallengeSnapshot snapshot);
}

class InMemoryWeeklyChallengeStore implements WeeklyChallengeStore {
  WeeklyChallengeSnapshot _snapshot = WeeklyChallengeSnapshot.initial;

  @override
  Future<WeeklyChallengeSnapshot> load() async => _snapshot;

  @override
  Future<void> save(WeeklyChallengeSnapshot snapshot) async => _snapshot = snapshot;
}

class WeeklyChallengeRepository {
  WeeklyChallengeRepository._(this._clock, this._store, this._snapshot);

  static const totalTarget = 15;

  final Clock _clock;
  final WeeklyChallengeStore _store;
  WeeklyChallengeSnapshot _snapshot;

  static DateTime _weekStartOf(DateTime at) {
    final dateOnly = DateTime(at.year, at.month, at.day);
    // DateTime.weekday: 月曜=1 ... 日曜=7。今週の月曜まで戻る。
    return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
  }

  static Future<WeeklyChallengeRepository> load({
    required Clock clock,
    required WeeklyChallengeStore store,
  }) async {
    final stored = await store.load();
    final currentWeekStart = _weekStartOf(clock.now());
    final snapshot = stored.weekStart == currentWeekStart
        ? stored
        : WeeklyChallengeSnapshot(weekStart: currentWeekStart, completedCount: 0);
    return WeeklyChallengeRepository._(clock, store, snapshot);
  }

  int get completedCount => _snapshot.completedCount;
  bool get isComplete => completedCount >= totalTarget;

  Future<void> recordCorrectAnswer() async {
    final currentWeekStart = _weekStartOf(_clock.now());
    final base = _snapshot.weekStart == currentWeekStart
        ? _snapshot
        : WeeklyChallengeSnapshot(weekStart: currentWeekStart, completedCount: 0);
    if (base.completedCount >= totalTarget) {
      _snapshot = base;
      return;
    }
    _snapshot = WeeklyChallengeSnapshot(
      weekStart: currentWeekStart,
      completedCount: base.completedCount + 1,
    );
    await _store.save(_snapshot);
  }
}
