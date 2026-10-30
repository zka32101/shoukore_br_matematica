import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'equipped_items.dart';
import 'locale_preference_store.dart';
import 'prefs_core_stores.dart';
import 'prefs_stores.dart';
import 'weekly_challenge_repository.dart';

/// アプリが使う、端末内の保存先をまとめたもの。起動時に1回だけ開く(`open`)。
/// すべて shared_preferences に保存する(理由は prefs_core_stores.dart の注記)。
/// 単体テストでは渡さず、画面側が、メモリ上の実装を使う。
class AppStorage {
  AppStorage._(SharedPreferences prefs)
    : progressStore = PrefsProgressStore(prefs),
      growthStore = PrefsGrowthStore(prefs),
      inventoryStore = PrefsInventoryStore(prefs),
      consentStore = PrefsConsentStore(prefs),
      screenTimeStore = PrefsScreenTimeStore(prefs),
      onboardingStore = PrefsOnboardingCompletionStore(prefs),
      localeStore = PrefsLocalePreferenceStore(prefs),
      characterCollectionStore = PrefsCharacterCollectionStore(prefs),
      equippedItemsStore = PrefsEquippedItemsStore(prefs),
      weeklyChallengeStore = PrefsWeeklyChallengeStore(prefs);

  final ProgressStore progressStore;
  final GrowthStore growthStore;
  final InventoryStore inventoryStore;
  final ConsentStore consentStore;
  final ScreenTimeStore screenTimeStore;
  final OnboardingCompletionStore onboardingStore;
  final LocalePreferenceStore localeStore;
  final CharacterCollectionStore characterCollectionStore;
  final EquippedItemsStore equippedItemsStore;
  final WeeklyChallengeStore weeklyChallengeStore;

  static Future<AppStorage> open() async {
    return AppStorage._(await SharedPreferences.getInstance());
  }
}
