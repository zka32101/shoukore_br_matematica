import 'package:shoukore_core_global/shoukore_core_global.dart';

/// 年齢確認・保護者同意の判定・記録ロジック（UI非依存）。
/// 設定画面のダイアログ版(`age_gate_dialog.dart`)とオンボーディングの
/// 必須ページ版(`onboarding_screen.dart`)の両方で同じ判定・記録ロジックを
/// 使うことで、挙動がずれないようにする（UIの見せ方はそれぞれに委ねる）。

/// 入力された生年から保護者同意が必要かを判定する。必要なければその場で
/// 「同意不要」の記録をして`false`を返す。必要なら何も記録せず`true`を
/// 返す（呼び出し側が保護者同意の質問を表示し、[recordConsentAnswer]で
/// 結果を記録する）。
Future<bool> requiresConsentAndRecordIfNot({
  required int birthYear,
  required RegionalProfile profile,
  required Clock clock,
  required ConsentStore consentStore,
}) async {
  final requiresConsent = const AgeGate().requiresGuardianConsent(
    birthYear: birthYear,
    profile: profile,
    clock: clock,
  );
  if (!requiresConsent) {
    await consentStore.setConsent(const ConsentRecord(parentalConsentGiven: false));
  }
  return requiresConsent;
}

/// 保護者同意の質問への回答を記録する。
Future<void> recordConsentAnswer({
  required ConsentStore consentStore,
  required Clock clock,
  required bool accepted,
}) {
  return consentStore.setConsent(ConsentRecord(
    parentalConsentGiven: accepted,
    consentedAt: accepted ? clock.now() : null,
  ));
}
