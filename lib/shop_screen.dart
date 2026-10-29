import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'equipped_items.dart';
import 'growth_repository.dart';
import 'l10n/app_localizations.dart';
import 'shop_catalog.dart';

/// コインでアバター用アイテムを購入できるショップ画面。価格判定・購入処理は
/// コア側の`InventoryManager`に委ね、本画面は表示とユーザー操作のみを担う。
/// 購入済みアイテムは「使う(装着)」ボタンでキャラの見た目に反映できる
/// (`EquippedItems`、どれを今使うかはアプリ側の表示専用の状態)。
class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.growthRepository,
    required this.inventoryStore,
    required this.inventory,
    required this.onInventoryChanged,
    required this.equippedItemsStore,
    required this.equippedItems,
    required this.onEquippedItemsChanged,
  });

  final GrowthRepository growthRepository;
  final InventoryStore inventoryStore;
  final InventorySnapshot inventory;
  final ValueChanged<InventorySnapshot> onInventoryChanged;
  final EquippedItemsStore equippedItemsStore;
  final EquippedItems equippedItems;
  final ValueChanged<EquippedItems> onEquippedItemsChanged;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _inventoryManager = InventoryManager();

  late CoinWallet _wallet = widget.growthRepository.wallet;
  late InventorySnapshot _inventory = widget.inventory;
  late EquippedItems _equipped = widget.equippedItems;
  bool _purchaseInProgress = false;

  String? _equippedIdFor(ShopItemCategory category) {
    switch (category) {
      case ShopItemCategory.hat:
        return _equipped.hatItemId;
      case ShopItemCategory.background:
        return _equipped.backgroundItemId;
      case ShopItemCategory.frame:
        return _equipped.frameItemId;
    }
  }

  Future<void> _purchase(StoreItem item) async {
    // 連打による二重購入(コインの二重課金)を防ぐため、処理中は後続のタップを
    // 無視する。
    if (_purchaseInProgress) return;
    _purchaseInProgress = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      if (!_inventoryManager.canPurchase(
        wallet: _wallet,
        inventory: _inventory,
        item: item,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shopInsufficientCoinsMessage)),
        );
        return;
      }
      final result = _inventoryManager.purchase(
        wallet: _wallet,
        inventory: _inventory,
        item: item,
      );
      await widget.inventoryStore.save(result.inventory);
      await widget.growthRepository.applyWallet(result.wallet);
      if (!mounted) return;
      setState(() {
        _wallet = result.wallet;
        _inventory = result.inventory;
      });
      widget.onInventoryChanged(result.inventory);
      // 購入直後、そのカテゴリで何も使っていなければそのまま装着し、すぐに
      // 見た目の変化を実感できるようにする。
      if (_equippedIdFor(shopItemCategory(item.id)) == null) {
        await _equip(item);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shopPurchaseSuccessMessage)),
      );
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> _equip(StoreItem item) async {
    final category = shopItemCategory(item.id);
    final next = switch (category) {
      ShopItemCategory.hat => _equipped.copyWith(hatItemId: () => item.id),
      ShopItemCategory.background => _equipped.copyWith(backgroundItemId: () => item.id),
      ShopItemCategory.frame => _equipped.copyWith(frameItemId: () => item.id),
    };
    await widget.equippedItemsStore.save(next);
    if (!mounted) return;
    setState(() => _equipped = next);
    widget.onEquippedItemsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                key: const Key('shopBalanceTile'),
                leading: Icon(
                  Icons.monetization_on,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                title: Text(
                  l10n.shopBalanceLabel,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
                trailing: Text(
                  '${_wallet.balance}',
                  key: const Key('shopBalanceText'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in shopCatalog)
                  _ShopItemCard(
                    key: Key('shopItem_${item.id}'),
                    item: item,
                    owned: _inventory.owns(item.id),
                    inUse: _equippedIdFor(shopItemCategory(item.id)) == item.id,
                    canAfford: _wallet.balance >= item.priceCoins,
                    onBuy: () => _purchase(item),
                    onUse: () => _equip(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    super.key,
    required this.item,
    required this.owned,
    required this.inUse,
    required this.canAfford,
    required this.onBuy,
    required this.onUse,
  });

  final StoreItem item;
  final bool owned;
  final bool inUse;
  final bool canAfford;
  final VoidCallback onBuy;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: Icon(shopItemIcon(item.id)),
        ),
        title: Text(shopItemName(l10n, item.id)),
        subtitle: Text(shopItemDescription(l10n, item.id)),
        trailing: !owned
            ? FilledButton(
                key: Key('shopBuyButton_${item.id}'),
                onPressed: canAfford ? onBuy : null,
                child: Text('${l10n.shopBuyButton} (${item.priceCoins})'),
              )
            : inUse
                ? Chip(
                    key: Key('shopInUseLabel_${item.id}'),
                    label: Text(l10n.shopInUseLabel),
                  )
                : OutlinedButton(
                    key: Key('shopUseButton_${item.id}'),
                    onPressed: onUse,
                    child: Text(l10n.shopUseButton),
                  ),
      ),
    );
  }
}
