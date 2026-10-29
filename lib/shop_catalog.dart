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

/// アイテムの装着先カテゴリ。キャラ画像への反映時にどの表現(帽子/背景/枠)を
/// 使うかを決める。カテゴリはidの接頭辞で判定する(帽子=hat_、背景=bg_、
/// 枠=frame_)。
enum ShopItemCategory { hat, background, frame }

ShopItemCategory shopItemCategory(String itemId) {
  if (itemId.startsWith('hat_')) return ShopItemCategory.hat;
  if (itemId.startsWith('bg_')) return ShopItemCategory.background;
  if (itemId.startsWith('frame_')) return ShopItemCategory.frame;
  throw ArgumentError.value(itemId, 'itemId', 'unknown shop item category prefix');
}

/// 背景アイテムをキャラカードに反映する際の色。
Color shopBackgroundColor(String itemId) {
  switch (itemId) {
    case 'bg_blackboard':
      return const Color(0xFF263238);
    case 'bg_stars':
      return const Color(0xFF1A237E);
  }
  return Colors.transparent;
}

/// 枠アイテムをキャラカードに反映する際の色(グラデーション枠は単色で代替)。
Color shopFrameColor(String itemId) {
  switch (itemId) {
    case 'frame_gold':
      return const Color(0xFFFFD700);
    case 'frame_rainbow':
      return const Color(0xFFE040FB);
  }
  return Colors.transparent;
}
