import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/equipped_items.dart';
import 'package:shoukore_br_matematica/growth_repository.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/shop_screen.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

void main() {
  testWidgets('ショップで購入すると残高が減りアイテムが所持済みになる', (tester) async {
    final growthStore = InMemoryGrowthStore();
    // hat_calculatorの価格(30)を購入でき、hat_ruler(30)は買えない残高にする。
    await growthStore.save(const GrowthSnapshot(coinBalance: 40));
    final growthRepository = await GrowthRepository.load(
      clock: const SystemClock(),
      profile: const RegionalProfile(
        locale: 'pt_BR',
        ageOfConsent: 13,
        guardianConsentRequired: true,
        dailyResetHour: 5,
        timeZone: 'America/Sao_Paulo',
        screenTimeLimitMinutes: 0,
        profilingAdsAllowed: false,
      ),
      store: growthStore,
    );
    final inventoryStore = InMemoryInventoryStore();
    final equippedItemsStore = InMemoryEquippedItemsStore();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: ShopScreen(
          growthRepository: growthRepository,
          inventoryStore: inventoryStore,
          inventory: InventorySnapshot.initial,
          onInventoryChanged: (_) {},
          equippedItemsStore: equippedItemsStore,
          equippedItems: EquippedItems.initial,
          onEquippedItemsChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('40'), findsOneWidget);
    expect(find.byKey(const Key('shopBuyButton_hat_calculator')), findsOneWidget);
    expect(find.byKey(const Key('shopInUseLabel_hat_calculator')), findsNothing);

    await tester.tap(find.byKey(const Key('shopBuyButton_hat_calculator')));
    await tester.pumpAndSettle();

    // 購入したアイテムは、同カテゴリで他に何も使っていなければ自動的に装着される。
    expect(find.text('10'), findsOneWidget);
    expect(find.byKey(const Key('shopInUseLabel_hat_calculator')), findsOneWidget);
    expect(find.byKey(const Key('shopBuyButton_hat_calculator')), findsNothing);

    // hat_ruler(30コイン)は残高10では購入できないため、ボタンが無効になる。
    final rulerButton = tester.widget<FilledButton>(
      find.byKey(const Key('shopBuyButton_hat_ruler')),
    );
    expect(rulerButton.onPressed, isNull);

    final savedInventory = await inventoryStore.load();
    expect(savedInventory.owns('hat_calculator'), isTrue);
    expect(growthRepository.wallet.balance, 10);

    final savedEquipped = await equippedItemsStore.load();
    expect(savedEquipped.hatItemId, 'hat_calculator');
  });
}
