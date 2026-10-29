import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'growth_repository.dart';
import 'l10n/app_localizations.dart';
import 'shop_catalog.dart';

/// コインでアバター用アイテムを購入できるショップ画面。価格判定・購入処理は
/// コア側の`InventoryManager`に委ね、本画面は表示とユーザー操作のみを担う。
class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.growthRepository,
    required this.inventoryStore,
    required this.inventory,
    required this.onInventoryChanged,
  });

  final GrowthRepository growthRepository;
  final InventoryStore inventoryStore;
  final InventorySnapshot inventory;
  final ValueChanged<InventorySnapshot> onInventoryChanged;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _inventoryManager = InventoryManager();

  late CoinWallet _wallet = widget.growthRepository.wallet;
  late InventorySnapshot _inventory = widget.inventory;

  Future<void> _purchase(StoreItem item) async {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shopPurchaseSuccessMessage)),
    );
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
                    canAfford: _wallet.balance >= item.priceCoins,
                    onBuy: () => _purchase(item),
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
    required this.canAfford,
    required this.onBuy,
  });

  final StoreItem item;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

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
        trailing: owned
            ? Chip(
                key: Key('shopOwnedLabel_${item.id}'),
                label: Text(l10n.shopOwnedLabel),
              )
            : FilledButton(
                key: Key('shopBuyButton_${item.id}'),
                onPressed: canAfford ? onBuy : null,
                child: Text('${l10n.shopBuyButton} (${item.priceCoins})'),
              ),
      ),
    );
  }
}
