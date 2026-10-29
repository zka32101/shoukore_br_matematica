/// 購入済みアイテムのうち、現在キャラの見た目に反映する(装着する)アイテムの
/// 選択状態。所持判定(`InventorySnapshot`)はコア側が持つが、「どれを今使うか」は
/// 表示のみに関わるアプリ側の責務のため、ここで保持する。
class EquippedItems {
  const EquippedItems({this.hatItemId, this.backgroundItemId, this.frameItemId});

  static const initial = EquippedItems();

  final String? hatItemId;
  final String? backgroundItemId;
  final String? frameItemId;

  EquippedItems copyWith({
    String? Function()? hatItemId,
    String? Function()? backgroundItemId,
    String? Function()? frameItemId,
  }) {
    return EquippedItems(
      hatItemId: hatItemId != null ? hatItemId() : this.hatItemId,
      backgroundItemId: backgroundItemId != null ? backgroundItemId() : this.backgroundItemId,
      frameItemId: frameItemId != null ? frameItemId() : this.frameItemId,
    );
  }
}

/// `EquippedItems`の永続化先。
abstract class EquippedItemsStore {
  Future<EquippedItems> load();
  Future<void> save(EquippedItems items);
}

/// 結合テストで検証しやすいメモリ上実装。
class InMemoryEquippedItemsStore implements EquippedItemsStore {
  EquippedItems _items = EquippedItems.initial;

  @override
  Future<EquippedItems> load() async => _items;

  @override
  Future<void> save(EquippedItems items) async {
    _items = items;
  }
}
