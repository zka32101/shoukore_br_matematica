import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

import 'character_definition.dart';

/// `CharacterCollectionRepository.refresh`の結果。保存後のスナップショットに
/// 加えて、新規所持・レベルアップの変化（演出トリガー用）を含む。
class CharacterCollectionRefreshResult {
  const CharacterCollectionRefreshResult({
    required this.snapshot,
    required this.newlyOwned,
    required this.leveledUp,
  });

  final CharacterCollectionSnapshot snapshot;
  final Set<String> newlyOwned;
  final Map<String, int> leveledUp;

  bool get hasChanges => newlyOwned.isNotEmpty || leveledUp.isNotEmpty;
}

/// eixoごとの累積正解数から、キャラの所持状態・育成レベルを計算し
/// `CharacterCollectionStore`に保存する。
///
/// レベル計算自体はcoreの`CharacterGrowthCalculator`（教科非依存の順送り
/// ロジック）に委譲し、本クラスは「どの単元がどのeixo/キャラに属するか」
/// というアプリ固有のマッピングのみを担う。永続化された経験値は持たず、
/// `ProgressStore`のAttempt履歴から毎回再計算する（`MasteryDecay`等と
/// 同様の設計）。
class CharacterCollectionRepository {
  CharacterCollectionRepository({
    required this.progressStore,
    required this.collectionStore,
    this.growthCalculator = const CharacterGrowthCalculator(),
  });

  static const _changeDetector = CharacterCollectionChangeDetector();

  final ProgressStore progressStore;
  final CharacterCollectionStore collectionStore;
  final CharacterGrowthCalculator growthCalculator;

  /// [units]（現在のカリキュラム単元一覧）を元に、各eixoの累積正解数を
  /// 集計してキャラの所持状態・レベルを再計算し、保存する。
  Future<CharacterCollectionRefreshResult> refresh(List<Unit> units) async {
    final before = await collectionStore.load();

    final correctCountByEixo = <String, int>{};
    for (final eixoKeyword in characterDefinitions.map((c) => c.eixoKeyword).toSet()) {
      var count = 0;
      for (final unit in units.where((u) => u.id.contains(eixoKeyword))) {
        final attempts = await progressStore.getAttempts(unit.id);
        count += attempts.where((a) => a.correct).length;
      }
      correctCountByEixo[eixoKeyword] = count;
    }

    final levelByCharacterId = <String, int>{};
    for (final def in characterDefinitions) {
      final eixoCorrectCount = correctCountByEixo[def.eixoKeyword] ?? 0;
      final level = growthCalculator.levelForOrder(def.order, eixoCorrectCount);
      if (level > 0) levelByCharacterId[def.id] = level;
    }

    final after = CharacterCollectionSnapshot(levelByCharacterId: levelByCharacterId);
    await collectionStore.save(after);

    return CharacterCollectionRefreshResult(
      snapshot: after,
      newlyOwned: _changeDetector.newlyOwned(before: before, after: after),
      leveledUp: _changeDetector.leveledUp(before: before, after: after),
    );
  }
}
