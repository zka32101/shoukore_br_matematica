import 'package:flutter/material.dart';

import 'character_definition.dart';

/// コレクションキャラ1体分の所持状態・育成レベルを表示するカード。
/// 未所持（レベル0）はグレーアウト+ロックアイコン表示にする。
/// ホーム画面のプレビュー・コレクション画面の両方から使う共有ウィジェット。
class CharacterCard extends StatelessWidget {
  const CharacterCard({super.key, required this.definition, required this.level});

  final CharacterDefinition definition;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owned = level > 0;
    final color = owned ? definition.color : theme.colorScheme.outlineVariant;
    // 未所持のキャラは、画像アセットがあってもネタバレしないようアイコンの
    // ままにする（"???"表示と一貫させる）。
    final imagePath = owned ? definition.imageAssetPath(level) : null;
    return SizedBox(
      width: 96,
      height: 110,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
