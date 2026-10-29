import 'package:flutter/material.dart';

import 'character_definition.dart';
import 'equipped_items.dart';
import 'shop_catalog.dart';

/// コレクションキャラ1体分の所持状態・育成レベルを表示するカード。
/// 未所持（レベル0）はグレーアウト+ロックアイコン表示にする。
/// ホーム画面のプレビュー・コレクション画面の両方から使う共有ウィジェット。
/// [equippedItems]を渡すと、ショップで購入し「使う」に設定したアイテムが
/// 帽子(上部アイコン)・背景(アバターの縁取り色)・枠(アバターの枠線)として
/// 見た目に反映される。
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.definition,
    required this.level,
    this.equippedItems,
  });

  final CharacterDefinition definition;
  final int level;
  final EquippedItems? equippedItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owned = level > 0;
    final color = owned ? definition.color : theme.colorScheme.outlineVariant;
    // 未所持のキャラは、画像アセットがあってもネタバレしないようアイコンの
    // ままにする（"???"表示と一貫させる）。
    final imagePath = owned ? definition.imageAssetPath(level) : null;
    final backgroundItemId = owned ? equippedItems?.backgroundItemId : null;
    final frameItemId = owned ? equippedItems?.frameItemId : null;
    final hatItemId = owned ? equippedItems?.hatItemId : null;
    final backgroundColor =
        backgroundItemId == null ? color : shopBackgroundColor(backgroundItemId);
    final frameColor = frameItemId == null ? null : shopFrameColor(frameItemId);
    return SizedBox(
      width: 96,
      height: 110,
      child: Material(
        color: backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    key: frameColor == null ? null : const Key('characterFrameBorder'),
                    decoration: frameColor == null
                        ? null
                        : BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: frameColor, width: 3),
                          ),
                    padding: frameColor == null ? EdgeInsets.zero : const EdgeInsets.all(2),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          child: imagePath == null
                              ? Icon(definition.icon, size: 20)
                              : ClipOval(
                                  child: Image.asset(
                                    imagePath,
                                    key: const Key('characterImage'),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    // アセットがまだ配置されていない開発・CI環境でも
                                    // 落ちないよう、読み込み失敗時はアイコンに戻す。
                                    errorBuilder: (_, __, ___) => Icon(definition.icon, size: 20),
                                  ),
                                ),
                        ),
                        if (hatItemId != null)
                          Positioned(
                            top: -8,
                            left: 10,
                            child: Icon(
                              shopItemIcon(hatItemId),
                              key: const Key('characterHatIcon'),
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    definition.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    owned ? characterLevelLabels[level] : '???',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (!owned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.lock,
                    key: const Key('characterLockIcon'),
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
