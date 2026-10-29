import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'character_definition.dart';
import 'l10n/app_localizations.dart';

/// キャラの新規所持・レベルアップ1件分を表す、演出トリガー用のデータ。
class CharacterGrowthCelebration {
  const CharacterGrowthCelebration({
    required this.character,
    required this.level,
    required this.newlyOwned,
  });

  final CharacterDefinition character;
  final int level;

  /// trueなら「新しい仲間」演出、falseなら「レベルアップ」演出にする。
  final bool newlyOwned;
}

/// キャラの新規所持・レベルアップを、以前のSnackBarより大きく祝う
/// 専用ダイアログ。複数件あれば1件ずつ順番に表示する（「もっと見る」を
/// 連打しなくても自然に次へ進む）。
/// 第三者パッケージ(confetti等)は使わず、`AnswerFeedbackAnimation`と同様に
/// Flutter標準の`AnimationController`のみで星の粒・弾む登場を表現する。
Future<void> showCharacterGrowthCelebrations(
  BuildContext context,
  List<CharacterGrowthCelebration> celebrations,
) async {
  for (final celebration in celebrations) {
    if (!context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CharacterGrowthCelebrationDialog(celebration: celebration),
    );
  }
}

class CharacterGrowthCelebrationDialog extends StatefulWidget {
  const CharacterGrowthCelebrationDialog({super.key, required this.celebration});

  final CharacterGrowthCelebration celebration;

  @override
  State<CharacterGrowthCelebrationDialog> createState() =>
      _CharacterGrowthCelebrationDialogState();
}

class _CharacterGrowthCelebrationDialogState extends State<CharacterGrowthCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  static const _burstOffsets = [
    (-1.0, -0.6),
    (-0.3, -1.1),
    (0.4, -1.0),
    (1.0, -0.5),
    (-0.8, 0.3),
    (0.9, 0.4),
    (0.0, -1.3),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final character = widget.celebration.character;
    final level = widget.celebration.level;
    final imagePath = character.imageAssetPath(level);

    return Dialog(
      key: const Key('characterGrowthCelebrationDialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.celebration.newlyOwned
                  ? l10n.characterCelebrationNewlyOwnedTitle
                  : l10n.characterCelebrationLeveledUpTitle,
              key: const Key('characterGrowthCelebrationTitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < _burstOffsets.length; i++)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final (dx, dy) = _burstOffsets[i];
                        final progress = Curves.easeOut.transform(_controller.value);
                        final opacity = (1 - progress).clamp(0.0, 1.0);
                        return Positioned(
                          left: 80 + dx * 90 * progress - 10,
                          top: 80 + dy * 90 * progress - 10,
                          child: Opacity(
                            opacity: opacity,
                            child: Icon(Icons.star, size: 20, color: Colors.amber),
                          ),
                        );
                      },
                    ),
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: character.color,
                      foregroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          imagePath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(character.icon, size: 48),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              character.name,
              key: const Key('characterGrowthCelebrationName'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            _LevelBadge(label: characterLevelLabel(l10n, level)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('characterGrowthCelebrationContinueButton'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.characterCelebrationContinueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
