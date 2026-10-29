import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

/// テストから時刻を操作できるFakeClock。
class _FakeClock implements Clock {
  _FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

void main() {
  const profile = RegionalProfile(
    locale: 'pt_BR',
    ageOfConsent: 13,
    guardianConsentRequired: true,
    dailyResetHour: 5,
    timeZone: 'America/Sao_Paulo',
    screenTimeLimitMinutes: 0,
    profilingAdsAllowed: false,
  );

  test('ボーナスコインは1日の上限(20)を超えて獲得できない', () async {
    final clock = _FakeClock(DateTime.utc(2026, 10, 29, 10));
    final repository = await GrowthRepository.load(
      clock: clock,
      profile: profile,
      store: InMemoryGrowthStore(),
    );

    // +2ずつ10回(=20)はすべて満額付与される。
    for (var i = 0; i < 10; i++) {
      final granted = await repository.earnBonusCoins(2);
      expect(granted, 2);
    }
    expect(repository.wallet.balance, 20);

    // 11回目(上限超過分)は何も付与されない。
    final capped = await repository.earnBonusCoins(2);
    expect(capped, 0);
    expect(repository.wallet.balance, 20);
  });

  test('日付が変わると上限がリセットされる', () async {
    final clock = _FakeClock(DateTime.utc(2026, 10, 29, 10));
    final repository = await GrowthRepository.load(
      clock: clock,
      profile: profile,
      store: InMemoryGrowthStore(),
    );

    for (var i = 0; i < 10; i++) {
      await repository.earnBonusCoins(2);
    }
    expect(repository.wallet.balance, 20);
    expect(await repository.earnBonusCoins(2), 0);

    // 翌日(dailyResetHour=5を越える)に進めると、再び獲得できる。
    clock.advance(const Duration(days: 1));
    final grantedNextDay = await repository.earnBonusCoins(2);
    expect(grantedNextDay, 2);
    expect(repository.wallet.balance, 22);
  });

  test('上限に満たない端数は残り分だけ付与される', () async {
    final clock = _FakeClock(DateTime.utc(2026, 10, 29, 10));
    final repository = await GrowthRepository.load(
      clock: clock,
      profile: profile,
      store: InMemoryGrowthStore(),
    );

    for (var i = 0; i < 9; i++) {
      await repository.earnBonusCoins(2);
    }
    expect(repository.wallet.balance, 18);

    // 残り枠は2だが、3コインを要求 → 上限2までしか付与されない。
    final granted = await repository.earnBonusCoins(3);
    expect(granted, 2);
    expect(repository.wallet.balance, 20);
  });
}
