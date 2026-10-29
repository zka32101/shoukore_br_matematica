import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// ショップで販売するアイテムの一覧。コア側(`StoreItem`)はid・価格のみを
/// 保持するため、表示名・説明・アイコンはアプリ側のこのファイルとl10nが持つ。
const shopCatalog = <StoreItem>[
  StoreItem(id: 'hat_calculator', priceCoins: 30),
  StoreItem(id: 'hat_ruler', priceCoins: 30),
  StoreItem(id: 'bg_blackboard', priceCoins: 50),
  StoreItem(id: 'bg_stars', priceCoins: 50),
  StoreItem(id: 'frame_gold', priceCoins: 80),
  StoreItem(id: 'frame_rainbow', priceCoins: 80),
];

String shopItemName(AppLocalizations l10n, String itemId) {
  switch (itemId) {
    case 'hat_calculator':
      return l10n.shopItemHatCalculator;
    case 'hat_ruler':
      return l10n.shopItemHatRuler;
    case 'bg_blackboard':
      return l10n.shopItemBgBlackboard;
    case 'bg_stars':
      return l10n.shopItemBgStars;
    case 'frame_gold':
      return l10n.shopItemFrameGold;
    case 'frame_rainbow':
      return l10n.shopItemFrameRainbow;
  }
  return itemId;
}

String shopItemDescription(AppLocalizations l10n, String itemId) {
  switch (itemId) {
    case 'hat_calculator':
      return l10n.shopItemHatCalculatorDescription;
    case 'hat_ruler':
      return l10n.shopItemHatRulerDescription;
    case 'bg_blackboard':
      return l10n.shopItemBgBlackboardDescription;
    case 'bg_stars':
      return l10n.shopItemBgStarsDescription;
    case 'frame_gold':
      return l10n.shopItemFrameGoldDescription;
    case 'frame_rainbow':
      return l10n.shopItemFrameRainbowDescription;
  }
  return '';
}

IconData shopItemIcon(String itemId) {
  switch (itemId) {
    case 'hat_calculator':
    case 'hat_ruler':
      return Icons.checkroom;
    case 'bg_blackboard':
    case 'bg_stars':
      return Icons.image;
    case 'frame_gold':
    case 'frame_rainbow':
      return Icons.crop_square;
  }
  return Icons.star;
}
