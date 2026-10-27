import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// 年齢確認（生まれ年の入力）を行い、`AgeGate`で保護者同意の要否を判定する。
/// 同意が必要な場合は`consentDialog`で保護者同意フローへ遷移し、結果を
/// `ConsentStore`に記録する。
Future<void> showAgeGateFlow(
  BuildContext context, {
  required RegionalProfile profile,
  required Clock clock,
  required ConsentStore consentStore,
}) async {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;

  final birthYear = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.ageGateTitle),
        content: TextField(
          key: const Key('birthYearField'),
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l10n.ageGateBirthYearHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            key: const Key('ageGateConfirmButton'),
            onPressed: () => Navigator.of(context).pop(int.tryParse(controller.text)),
            child: Text(l10n.ageGateConfirmButton),
          ),
        ],
      );
    },
  );
  if (birthYear == null || !context.mounted) return;

  final requiresConsent = const AgeGate().requiresGuardianConsent(
    birthYear: birthYear,
    profile: profile,
    clock: clock,
  );

  if (!requiresConsent) {
    await consentStore.setConsent(const ConsentRecord(parentalConsentGiven: false));
    return;
  }

  if (!context.mounted) return;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.consentTitle),
      content: Text(l10n.consentBody),
      actions: [
        TextButton(
          key: const Key('consentDeclineButton'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.consentDeclineButton),
        ),
        TextButton(
          key: const Key('consentAcceptButton'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.consentAcceptButton),
        ),
      ],
    ),
  );

  await consentStore.setConsent(ConsentRecord(
    parentalConsentGiven: accepted ?? false,
    consentedAt: (accepted ?? false) ? clock.now() : null,
  ));
}
