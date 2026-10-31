import 'package:shoukore_core_global/shoukore_core_global.dart';

/// JP版(sansu-kore)の「ウィークリーチャレンジ」に相当する、今週あと何問
/// 正解すれば達成できるかを示す短期目標。デイリーのストリークだけでは
/// 「今日の分は終わった後にもう一度開く理由」が薄いため、週単位の目標を
/// 追加して定着率を上げる狙い。判定ロジック自体はcoreの
/// `WeeklyChallengeRules`(教科・国に依存しない純粋ロジック)に委譲し、
/// 本クラスは永続化(`WeeklyChallengeStore`)との橋渡しのみ担う。
abstract class WeeklyChallengeStore {
  Future<WeeklyChallengeState> load();
  Future<void> save(WeeklyChallengeState state);
}

class InMemoryWeeklyChallengeStore implements WeeklyChallengeStore {
  WeeklyChallengeState _state = WeeklyChallengeState.initial;

  @override
  Future<WeeklyChallengeState> load() async => _state;

  @override
  Future<void> save(WeeklyChallengeState state) async => _state = state;
}

class WeeklyChallengeRepository {
  WeeklyChallengeRepository._(this._clock, this._store, this._state);

  static const totalTarget = 15;
  static const _rules = WeeklyChallengeRules(totalTarget: totalTarget);

  final Clock _clock;
  final WeeklyChallengeStore _store;
  WeeklyChallengeState _state;

  static Future<WeeklyChallengeRepository> load({
    required Clock clock,
    required WeeklyChallengeStore store,
  }) async {
    final stored = await store.load();
    final state = _rules.currentState(stored: stored, now: clock.now());
    return WeeklyChallengeRepository._(clock, store, state);
  }

  int get completedCount => _state.completedCount;
  bool get isComplete => completedCount >= totalTarget;

  Future<void> recordCorrectAnswer() async {
    final base = _rules.currentState(stored: _state, now: _clock.now());
    if (base.completedCount >= totalTarget) {
      _state = base;
      return;
    }
    _state = _rules.recordCorrectAnswer(previous: base, now: _clock.now());
    await _store.save(_state);
  }
}
