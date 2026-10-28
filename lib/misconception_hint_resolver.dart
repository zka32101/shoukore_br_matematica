import 'l10n/app_localizations.dart';

/// `Question.misconceptionTags`の値（誤解の型）を、誤答直後に表示する
/// 具体的なヒント文言に解決する。コア側はタグのみ保持し、実際の文言は
/// アプリのl10nに委ねる設計（`explanation_resolver.dart`と同様のパターン）。
String? resolveMisconceptionHint(AppLocalizations l10n, String misconceptionTag) {
  switch (misconceptionTag) {
    case 'subtraction_as_addition':
      return l10n.misconceptionHintSubtractionAsAddition;
    default:
      return null;
  }
}
