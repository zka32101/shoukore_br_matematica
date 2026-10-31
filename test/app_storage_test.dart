import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'package:shoukore_br_matematica/app_storage.dart';
import 'package:shoukore_br_matematica/equipped_items.dart';
import 'package:shoukore_br_matematica/prefs_core_stores.dart';

/// アプリを閉じて開き直した状態(2つ目の AppStorage)で、記録が残っているかを確かめる。
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppStorage> reopen() async {
    // SharedPreferences.getInstance() は同じ値を返すので、保存済みの内容は引き継がれる。
    return AppStorage.open();
  }

  test('回答の記録と習熟度が、開き直しても残る', () async {
    final first = await AppStorage.open();
    await first.progressStore.recordAttempt(
      Attempt(
        questionId: 'q1',
        unitId: 'u1',
        correct: true,
        answeredAt: DateTime(2026, 10, 30, 12),
        chosenId: '11',
      ),
    );
    await first.progressStore.recordAttempt(
      Attempt(
        questionId: 'q2',
        unitId: 'u1',
        correct: false,
        answeredAt: DateTime(2026, 10, 30, 12, 1),
      ),
    );

    final second = await reopen();
    final attempts = await second.progressStore.getAttempts('u1');
    expect(attempts, hasLength(2));
    expect(attempts.first.questionId, 'q2');
    expect((await second.progressStore.getMastery('u1')).score, 0.5);
  });

  test('回答の記録は、上限を超えたら古いものから消える', () async {
    final storage = await AppStorage.open();
    for (var i = 0; i < PrefsProgressStore.maxStoredAttempts + 5; i++) {
      await storage.progressStore.recordAttempt(
        Attempt(
          questionId: 'q$i',
          unitId: 'u1',
          correct: true,
          answeredAt: DateTime(2026, 10, 30).add(Duration(seconds: i)),
        ),
      );
    }
    final reopened = await reopen();
    final attempts = await reopened.progressStore.getAttempts('u1');
    expect(attempts, hasLength(PrefsProgressStore.maxStoredAttempts));
    expect(attempts.last.questionId, 'q5');
  });

  test('コイン・成長・持ち物・同意・利用時間・キャラ・着せ替え・週のチャレンジが残る', () async {
    final first = await AppStorage.open();
    await first.growthStore.save(
      GrowthSnapshot(
        totalCorrectAnswers: 3,
        coinBalance: 40,
        currentStreakDays: 2,
        lastStudiedDay: DateTime(2026, 10, 30),
      ),
    );
    await first.inventoryStore.save(const InventorySnapshot(ownedItemIds: {'hat_calc'}));
    await first.consentStore.setConsent(
      ConsentRecord(parentalConsentGiven: true, consentedAt: DateTime(2026, 10, 30)),
    );
    await first.screenTimeStore.save(
      ScreenTimeSnapshot(usedTodayMinutes: 7, day: DateTime(2026, 10, 30)),
    );
    await first.characterCollectionStore.save(
      const CharacterCollectionSnapshot(levelByCharacterId: {'tucaninho': 2}),
    );
    await first.equippedItemsStore.save(const EquippedItems(hatItemId: 'hat_calc'));
    await first.weeklyChallengeStore.save(
      WeeklyChallengeState(weekStart: DateTime(2026, 10, 26), completedCount: 4),
    );

    final second = await reopen();
    final growth = await second.growthStore.load();
    expect(growth.coinBalance, 40);
    expect(growth.currentStreakDays, 2);
    expect(growth.lastStudiedDay, DateTime(2026, 10, 30));
    expect((await second.inventoryStore.load()).owns('hat_calc'), isTrue);
    final consent = await second.consentStore.getConsent();
    expect(consent?.parentalConsentGiven, isTrue);
    expect((await second.screenTimeStore.load()).usedTodayMinutes, 7);
    expect((await second.characterCollectionStore.load()).levelOf('tucaninho'), 2);
    expect((await second.equippedItemsStore.load()).hatItemId, 'hat_calc');
    final weekly = await second.weeklyChallengeStore.load();
    expect(weekly.completedCount, 4);
    expect(weekly.weekStart, DateTime(2026, 10, 26));
  });

  test('オンボーディングの完了と表示言語が残る', () async {
    final first = await AppStorage.open();
    expect(await first.onboardingStore.isCompleted(), isFalse);
    await first.onboardingStore.markCompleted();
    await first.localeStore.setLocale(const Locale('pt', 'BR'));

    final second = await reopen();
    expect(await second.onboardingStore.isCompleted(), isTrue);
    expect(await second.localeStore.getLocale(), const Locale('pt', 'BR'));
  });

  test('同意の取り消しと、全消去が効く', () async {
    final storage = await AppStorage.open();
    await storage.consentStore.setConsent(const ConsentRecord(parentalConsentGiven: true));
    await storage.consentStore.revokeConsent();
    expect((await storage.consentStore.getConsent())?.parentalConsentGiven, isFalse);
    await storage.consentStore.eraseAll();
    expect(await storage.consentStore.getConsent(), isNull);

    await storage.progressStore.recordAttempt(
      Attempt(questionId: 'q', unitId: 'u', correct: true, answeredAt: DateTime(2026, 10, 30)),
    );
    await storage.progressStore.clearAll();
    expect(await (await reopen()).progressStore.getAttempts('u'), isEmpty);
  });
}
