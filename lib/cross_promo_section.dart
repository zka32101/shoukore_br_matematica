import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cross_promo.dart';
import 'l10n/app_localizations.dart';

/// シリーズの他アプリへの案内枠。`crossPromoApps`が空の間は「近日公開」の
/// ティーザーのみ表示し、空のリンク一覧を出さない。他アプリが追加されたら
/// 自動でそのアプリ一覧に切り替わる。
class CrossPromoSection extends StatelessWidget {
  const CrossPromoSection({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (crossPromoApps.isEmpty) {
      return Card(
        key: const Key('crossPromoComingSoonCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.crossPromoComingSoonText),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final app in crossPromoApps)
          Card(
            key: Key('crossPromoCard_${app.id}'),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: app.color,
                foregroundColor: Colors.white,
                child: Icon(app.icon),
              ),
              title: Text(app.name),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(app.storeUrl),
            ),
          ),
      ],
    );
  }
}
