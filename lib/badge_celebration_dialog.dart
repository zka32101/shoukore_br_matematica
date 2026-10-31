import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'badge_image_resolver.dart';
import 'celebration_effects.dart';
import 'l10n/app_localizations.dart';

/// バッジ(単元マスター等)の新規獲得1件分を表す、演出トリガー用のデータ。
class BadgeCelebration {
  const BadgeCelebration({required this.unitLabel, required this.strandId});

  /// 画面に出す単元名(内部IDではなく、resolveUnitNameで解決済みの名前)。
  final String unitLabel;

  /// 表示するバッジ画像・差し色を決める、単元のストランドID
  /// (numbers/algebra/geometry/measurement/statistics等)。
  final String? strandId;
}

/// バッジの新規獲得を、以前のSnackBarより大きく祝う専用ダイアログ。
/// キャラ成長のお祝い(character_growth_celebration_dialog.dart)と同じ
/// CelebrationBurst演出を使い、複数件あれば1件ずつ順番に表示する。
Future<void> showBadgeCelebrations(
  BuildContext context,
  List<BadgeCelebration> celebrations,
) async {
  for (final celebration in celebrations) {
    if (!context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BadgeCelebrationDialog(celebration: celebration),
    );
  }
}

class BadgeCelebrationDialog extends StatefulWidget {
  const BadgeCelebrationDialog({super.key, required this.celebration});

  final BadgeCelebration celebration;

  @override
  State<BadgeCelebrationDialog> createState() => _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<BadgeCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final strandId = widget.celebration.strandId;
    final accentColor = strandId == null ? theme.colorScheme.primary : strandAccentColor(strandId);
    final badgeAsset = strandId == null ? null : masteryBadgeAsset(strandId);

    return Dialog(
      key: const Key('badgeCelebrationDialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.badgeCelebrationTitle,
              key: const Key('badgeCelebrationTitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CelebrationBurst(
              controller: _controller,
              size: 180,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accentColor.withValues(alpha: 0.3), accentColor.withValues(alpha: 0.05)],
                  ),
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                padding: const EdgeInsets.all(14),
                child: badgeAsset == null
                    ? Icon(Icons.emoji_events, size: 56, color: accentColor)
                    : Image.asset(
                        badgeAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.emoji_events, size: 56, color: accentColor),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.celebration.unitLabel,
              key: const Key('badgeCelebrationUnitLabel'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('badgeCelebrationContinueButton'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.badgeCelebrationContinueButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
