import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// LGPD上の権利行使（データ書き出し・削除・同意撤回）をまとめた保護者向け画面。
/// `exportUserData`/`eraseAllUserData`/`ConsentStore.revokeConsent`は
/// いずれもコア側に実装・単体テスト済みだったが、UI結合確認が未着手だった。
class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({
    super.key,
    required this.consentStore,
    required this.progressStore,
    required this.onDataErased,
  });

  final ConsentStore consentStore;
  final ProgressStore progressStore;
  final VoidCallback onDataErased;

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  Map<String, dynamic>? _exported;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exported = await exportUserData(
      consentStore: widget.consentStore,
      progressStore: widget.progressStore,
    );
    if (!mounted) return;
    setState(() => _exported = exported);
  }

  Future<void> _copyExportedJson() async {
    final json = await exportUserDataAsJson(
      consentStore: widget.consentStore,
      progressStore: widget.progressStore,
    );
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('dataExportedSnackBar'),
        content: Text(l10n.dataPrivacyExportCopiedMessage),
      ),
    );
  }

  Future<void> _revokeConsent() async {
    await widget.consentStore.revokeConsent();
    await _load();
  }

  Future<void> _eraseAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dataPrivacyEraseConfirmTitle),
        content: Text(l10n.dataPrivacyEraseConfirmBody),
        actions: [
          TextButton(
            key: const Key('eraseCancelButton'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.dataPrivacyEraseCancelButton),
          ),
          TextButton(
            key: const Key('eraseConfirmButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.dataPrivacyEraseConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await eraseAllUserData(
      consentStore: widget.consentStore,
      progressStore: widget.progressStore,
    );
    widget.onDataErased();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('dataErasedSnackBar'),
        content: Text(l10n.dataPrivacyErasedMessage),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exported = _exported;
    final consent = exported?['consent'] as Map<String, dynamic>?;
    final progressCount = (exported?['progress'] as List?)?.length ?? 0;
    final consentGiven = consent?['parentalConsentGiven'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataPrivacyTitle)),
      body: exported == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: consentGiven
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: Icon(
                      consentGiven ? Icons.verified_user : Icons.gpp_maybe_outlined,
                    ),
                    title: Text(
                      consentGiven ? l10n.consentStatusGiven : l10n.consentStatusNotGiven,
                      key: const Key('dataPrivacyConsentStatusText'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.dataPrivacyExportSectionTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      l10n.dataPrivacyProgressCount(progressCount),
                      key: const Key('dataPrivacyProgressCountText'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('copyExportedJsonButton'),
                  onPressed: _copyExportedJson,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(l10n.dataPrivacyCopyJsonButton),
                ),
                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('revokeConsentButton'),
                  onPressed: _revokeConsent,
                  icon: const Icon(Icons.block),
                  label: Text(l10n.dataPrivacyRevokeConsentButton),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('eraseAllButton'),
                  onPressed: _eraseAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.dataPrivacyEraseAllButton),
                ),
              ],
            ),
    );
  }
}
