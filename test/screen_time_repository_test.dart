import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'package:shoukore_br_matematica/screen_time_repository.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
}

RegionalProfile _profile({int screenTimeLimitMinutes = 0}) => RegionalProfile(
      locale: 'pt_BR',
      ageOfConsent: 12,
      guardianConsentRequired: true,
      dailyResetHour: 0,
      timeZone: 'America/Sao_Paulo',
      screenTimeLimitMinutes: screenTimeLimitMinutes,
      profilingAdsAllowed: false,
    );

void main() {
  test(
    '1分未満の短い利用(ScreenTimeSnapshotは分単位しか保持できない)を'
    '繰り返しても、秒単位の余りを保持して正しく積算される'
    '(ECA Digital対応の利用時間制限が機能し続けるための前提)',
    () async {
      final clock = _FixedClock(DateTime(2026, 1, 1, 10, 0));
      final store = InMemoryScreenTimeStore();
      final repo = await ScreenTimeRepository.load(
        clock: clock,
        boundary: DailyBoundary(_profile()),
        store: store,
      );

      // 40秒を3回 = 120秒 = 2分のはず(切り捨てのみだと毎回0分で合計0分になる)。
      await repo.addUsage(const Duration(seconds: 40));
      await repo.addUsage(const Duration(seconds: 40));
      await repo.addUsage(const Duration(seconds: 40));
      expect(repo.usedToday, const Duration(minutes: 2));
    },
  );

  test('ミッション日が変わると利用時間(秒の余りも含めて)がリセットされる', () async {
    final clock = _FixedClock(DateTime(2026, 1, 1, 23, 50));
    final store = InMemoryScreenTimeStore();
    final repo = await ScreenTimeRepository.load(
      clock: clock,
      boundary: DailyBoundary(_profile()),
      store: store,
    );

    await repo.addUsage(const Duration(seconds: 40));
    clock.advance(const Duration(hours: 1));
    await repo.addUsage(const Duration(seconds: 40));

    expect(repo.usedToday, Duration.zero);
  });
}
