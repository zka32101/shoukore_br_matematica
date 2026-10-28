import 'l10n/app_localizations.dart';

/// 四則演算問題のプロンプト文を組み立てる。`params['wordProblemId']`が設定されて
/// いれば実生活のイメージとリンクした文章題として表示し、未設定なら記号のみの
/// 数式として表示する（コア側は数値のみ保持し、文言はアプリのl10nに委ねる設計）。
String resolveArithmeticPrompt(
  AppLocalizations l10n, {
  required String operator,
  required int a,
  required int b,
  String? wordProblemId,
}) {
  if (wordProblemId != null && wordProblemId.isNotEmpty) {
    final wordProblem = _resolveWordProblem(l10n, wordProblemId, a, b);
    if (wordProblem != null) return wordProblem;
  }
  final symbol = switch (operator) {
    'add' => '+',
    'subtract' => '-',
    'multiply' => '×',
    'divide' => '÷',
    _ => '?',
  };
  return '$a $symbol $b = ?';
}

String? _resolveWordProblem(AppLocalizations l10n, String wordProblemId, int a, int b) {
  switch (wordProblemId) {
    case 'word_problem_add_fruits':
      return l10n.wordProblemAddFruits(a, b);
    case 'word_problem_add_coins':
      return l10n.wordProblemAddCoins(a, b);
    case 'word_problem_subtract_candies':
      return l10n.wordProblemSubtractCandies(a, b);
    case 'word_problem_subtract_stickers':
      return l10n.wordProblemSubtractStickers(a, b);
    case 'word_problem_multiply_boxes':
      return l10n.wordProblemMultiplyBoxes(a, b);
    case 'word_problem_multiply_rows':
      return l10n.wordProblemMultiplyRows(a, b);
    case 'word_problem_divide_friends':
      return l10n.wordProblemDivideFriends(a, b);
    case 'word_problem_divide_baskets':
      return l10n.wordProblemDivideBaskets(a, b);
    case 'word_problem_add_store':
      return l10n.wordProblemAddStore(a, b);
    case 'word_problem_subtract_change':
      return l10n.wordProblemSubtractChange(a, b);
    case 'word_problem_multiply_store':
      return l10n.wordProblemMultiplyStore(a, b);
    case 'word_problem_divide_store':
      return l10n.wordProblemDivideStore(a, b);
    case 'word_problem_add_people':
      return l10n.wordProblemAddPeople(a, b);
    case 'word_problem_subtract_people':
      return l10n.wordProblemSubtractPeople(a, b);
    case 'word_problem_multiply_people':
      return l10n.wordProblemMultiplyPeople(a, b);
    case 'word_problem_divide_people':
      return l10n.wordProblemDividePeople(a, b);
    case 'word_problem_add_budget':
      return l10n.wordProblemAddBudget(a, b);
    case 'word_problem_subtract_budget':
      return l10n.wordProblemSubtractBudget(a, b);
    case 'word_problem_multiply_budget':
      return l10n.wordProblemMultiplyBudget(a, b);
    case 'word_problem_divide_budget':
      return l10n.wordProblemDivideBudget(a, b);
    default:
      return null;
  }
}
