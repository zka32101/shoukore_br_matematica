import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// 保護者ゲート（2桁×2桁の乗算）。正しい答えを入力するまで通過できない。
Future<bool> showGuardianGateDialog(BuildContext context) async {
  final gate = GuardianGate();
  final challenge = gate.generateChallenge();
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      String? errorText;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.guardianGateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.guardianGateInstruction(challenge.a, challenge.b)),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              if (errorText != null) Text(errorText!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final input = int.tryParse(controller.text);
                if (input != null && gate.verify(challenge, input)) {
                  Navigator.of(context).pop(true);
                } else {
                  setState(() => errorText = l10n.guardianGateWrongAnswer);
                }
              },
              child: Text(l10n.guardianGateConfirmButton),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
