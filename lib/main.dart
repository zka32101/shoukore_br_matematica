import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'package:shoukore_core_global/shoukore_core_global_entitlement_revenuecat.dart';

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
import 'locale_preference_store.dart';
import 'onboarding_screen.dart';

/// RevenueCat APIキー。`--dart-define=REVENUECAT_API_KEY=...`で渡す。
/// 未設定（開発中・CI）の場合は空文字になり、実課金は一切呼び出さず、
/// premiumトグル模擬・固定の価格表示にフォールバックする。
const _revenueCatApiKey = String.fromEnvironment('REVENUECAT_API_KEY');

/// 教科ID(subjectId) → RevenueCatダッシュボードのentitlement識別子。
/// このアプリは算数(matematica)のみのため1件だが、RevenueCatダッシュボード
/// 側の実際の識別子と一致させる必要がある（お手元での設定作業）。
const _subjectEntitlementIds = {'matematica': 'matematica'};
const _premiumEntitlementId = 'premium';

void main() async {
  if (_revenueCatApiKey.isNotEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    await Purchases.configure(PurchasesConfiguration(_revenueCatApiKey));
  }
  runApp(const ShoukoreBrMatematicaApp());
}

class ShoukoreBrMatematicaApp extends StatefulWidget {
  const ShoukoreBrMatematicaApp({super.key});

  @override
  State<ShoukoreBrMatematicaApp> createState() => _ShoukoreBrMatematicaAppState();
}

class _ShoukoreBrMatematicaAppState extends State<ShoukoreBrMatematicaApp> {
  // BNCCカリキュラム自体はブラジル向けのみ(curriculum/pt_BR.json)のため、
  // 表示言語(_displayLocale)を切り替えてもカリキュラムの読み込みには影響
  // しない(HomeScreen側は常にpt_BRでカリキュラムを読み込む)。ここで切り替える
  // のはMaterialAppの表示言語(AppLocalizationsが解決する文言)のみ。
  Locale _displayLocale = const Locale('pt', 'BR');
  final LocalePreferenceStore _localePreferenceStore = InMemoryLocalePreferenceStore();

  final OnboardingCompletionStore _onboardingStore = InMemoryOnboardingCompletionStore();
  bool _loadingOnboardingState = true;
  bool _onboardingCompleted = false;

  // オンボーディングの年齢確認/保護者同意ステップとホーム画面の設定タイルが
  // 同じ同意記録を共有するよう、アプリ直下で1つだけ保持する。
  final ConsentStore _consentStore = InMemoryConsentStore();

  final RevenueCatEntitlementReader? _entitlementReader = _revenueCatApiKey.isEmpty
      ? null
      : RevenueCatEntitlementReader(
          subjectEntitlementIds: _subjectEntitlementIds,
          premiumEntitlementId: _premiumEntitlementId,
        );

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final completed = await _onboardingStore.isCompleted();
    final savedLocale = await _localePreferenceStore.getLocale();
    if (!mounted) return;
    setState(() {
      _onboardingCompleted = completed;
      _loadingOnboardingState = false;
      if (savedLocale != null) _displayLocale = savedLocale;
    });
  }

  Future<void> _changeLocale(Locale locale) async {
    await _localePreferenceStore.setLocale(locale);
    if (!mounted) return;
    setState(() => _displayLocale = locale);
  }

  @override
  Widget build(BuildContext context) {
    final seed = Colors.indigo;
    return MaterialApp(
      locale: _displayLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _loadingOnboardingState
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _onboardingCompleted
              ? HomeScreen(
                  entitlementReader: _entitlementReader,
                  consentStore: _consentStore,
                  displayLocale: _displayLocale,
                  onDisplayLocaleChanged: _changeLocale,
                )
              : OnboardingScreen(
                  completionStore: _onboardingStore,
                  entitlementReader: _entitlementReader,
                  consentStore: _consentStore,
                  onCompleted: () => setState(() => _onboardingCompleted = true),
                ),
    );
  }
}
