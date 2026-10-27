import 'l10n/app_localizations.dart';

/// `Question.explanationId`（コア共通の解説キー）をarb文言に解決する。
/// コア側はIDのみ保持し、実際の文言はアプリのl10nに委ねる設計（ADR参照）。
String? resolveExplanation(AppLocalizations l10n, String explanationId) {
  switch (explanationId) {
    case 'explanation_add':
      return l10n.explanationAdd;
    case 'explanation_subtract':
      return l10n.explanationSubtract;
    case 'explanation_multiply':
      return l10n.explanationMultiply;
    case 'explanation_divide':
      return l10n.explanationDivide;
    default:
      return null;
  }
}
