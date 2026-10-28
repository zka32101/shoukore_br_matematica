import 'package:shoukore_core_global/shoukore_core_global.dart' hide InMemoryProgressStore;

import 'character_definition.dart';

/// eixoごとの累積正解数から、キャラの所持状態・育成レベルを計算し
/// `CharacterCollectionStore`に保存する。
///
/// 育成ルール: 同じeixoに複数キャラがいる場合、[CharacterDefinition.order]の
/// 順に育成対象が移る（1体目がLv5まで育つと2体目の育成が始まる）。
/// レベルは[answersPerLevel]問正解するごとに1段階上がる（最大Lv5）。
/// 永続化された経験値は持たず、`ProgressStore`のAttempt履歴から毎回
/// 再計算する（`MasteryDecay`等と同様の設計）。
class CharacterCollectionRepository {
  CharacterCollectionRepository({
    required this.progressStore,
    required this.collectionStore,
  });

  static const answersPerLevel = 5;
  static const maxLevel = 5;
  static const _answersPerCharacter = answersPerLevel * maxLevel;

  final ProgressStore progressStore;
  final CharacterCollectionStore collectionStore;

  /// [units]（現在のカリキュラム単元一覧）を元に、各eixoの累積正解数を
  /// 集計してキャラの所持状態・レベルを再計算し、保存する。
  Future<CharacterCollectionSnapshot> refresh(List<Unit> units) async {
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
      final ownCorrectCount = eixoCorrectCount - def.order * _answersPerCharacter;
      if (ownCorrectCount <= 0) continue;
      final level = (ownCorrectCount / answersPerLevel).ceil().clamp(1, maxLevel);
      levelByCharacterId[def.id] = level;
    }

    final snapshot = CharacterCollectionSnapshot(levelByCharacterId: levelByCharacterId);
    await collectionStore.save(snapshot);
    return snapshot;
  }
}
