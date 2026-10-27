import 'package:shoukore_core_global/shoukore_core_global.dart';

/// サンプルアプリでの結合確認用の軽量実装。drift実装自体はコア側のテストで
/// 検証済みのため、ここでは `ProgressStore` 抽象とアプリ側の結合確認に専念する。
class InMemoryProgressStore implements ProgressStore {
  final List<Attempt> _attempts = [];

  @override
  Future<void> recordAttempt(Attempt attempt) async {
    _attempts.add(attempt);
  }

  @override
  Future<List<Attempt>> getAttempts(String unitId, {int? limit}) async {
    final filtered = _attempts.where((a) => a.unitId == unitId).toList()
      ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
    if (limit != null && filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  @override
  Future<Mastery> getMastery(String unitId) async {
    final recent = await getAttempts(unitId, limit: 20);
    if (recent.isEmpty) {
      return Mastery(unitId: unitId, score: 0, lastPracticedAt: null);
    }
    final correctCount = recent.where((a) => a.correct).length;
    return Mastery(
      unitId: unitId,
      score: correctCount / recent.length,
      lastPracticedAt: recent.first.answeredAt,
    );
  }

  @override
  Future<List<Mastery>> getAllMastery() async {
    final unitIds = _attempts.map((a) => a.unitId).toSet();
    return Future.wait(unitIds.map(getMastery));
  }

  @override
  Future<void> clearAll() async {
    _attempts.clear();
  }
}
