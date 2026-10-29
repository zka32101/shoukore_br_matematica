import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/daily_featured_unit.dart';

void main() {
  test('同じ日付なら常に同じ単元が選ばれる', () {
    final date = DateTime(2026, 3, 15);
    const unitIds = ['a', 'b', 'c', 'd'];
    final first = dailyFeaturedUnitId(date, unitIds);
    final second = dailyFeaturedUnitId(date, unitIds);
    expect(first, second);
    expect(unitIds, contains(first));
  });

  test('日付が変わると選ばれる単元が変わりうる', () {
    const unitIds = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
    final results = {
      for (var day = 1; day <= 7; day++) dailyFeaturedUnitId(DateTime(2026, 3, day), unitIds),
    };
    // 7日分で少なくとも2種類以上の単元が選ばれる(毎日固定ではない)ことを確認する。
    expect(results.length, greaterThan(1));
  });

  test('候補が空ならnullを返す', () {
    expect(dailyFeaturedUnitId(DateTime(2026, 3, 15), const []), isNull);
  });
}
