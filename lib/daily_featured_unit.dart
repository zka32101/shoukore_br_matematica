/// 「毎日使いたくなる仕掛け」として、日付ごとに決定的に1つの単元を
/// 「今日の挑戦」として選ぶ純関数。同じ日なら誰が開いても同じ単元が
/// 選ばれ、日が変われば違う単元になる(サーバー同期不要・端末時刻のみで
/// 完結する簡易な日替わりコンテンツ)。
String? dailyFeaturedUnitId(DateTime date, List<String> eligibleUnitIds) {
  if (eligibleUnitIds.isEmpty) return null;
  final dayOfYear = int.parse(
    '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}',
  );
  final index = dayOfYear % eligibleUnitIds.length;
  return eligibleUnitIds[index];
}
