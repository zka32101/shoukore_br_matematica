/// 文章題(wordProblemId)に対応するイメージ画像のアセットパスを返す。
/// 全ての文章題に画像があるわけではないため、対応が無ければnullを返す
/// (呼び出し側は画像を表示しないか、既存のテキストのみの表示にフォール
/// バックする)。
String? wordProblemImageAsset(String? wordProblemId) {
  switch (wordProblemId) {
    case 'word_problem_add_birthday':
      return 'assets/word_problems/birthday.png';
    case 'word_problem_add_bbq':
      return 'assets/word_problems/bbq.png';
    case 'word_problem_subtract_allowance':
      return 'assets/word_problems/allowance.png';
    case 'word_problem_multiply_market':
      return 'assets/word_problems/market.png';
    case 'word_problem_divide_recycling':
      return 'assets/word_problems/recycling.png';
    default:
      return null;
  }
}
