import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home_screen.dart';
import 'l10n/app_localizations.dart';
import 'onboarding_completion_store.dart';
import 'onboarding_screen.dart';

void main() {
  runApp(const ShoukoreBrMatematicaApp());
}

class ShoukoreBrMatematicaApp extends StatefulWidget {
  const ShoukoreBrMatematicaApp({super.key});

  @override
  State<ShoukoreBrMatematicaApp> createState() => _ShoukoreBrMatematicaAppState();
}

class _ShoukoreBrMatematicaAppState extends State<ShoukoreBrMatematicaApp> {
  static const _locale = Locale('pt', 'BR');

  final OnboardingCompletionStore _onboardingStore = InMemoryOnboardingCompletionStore();
  bool _loadingOnboardingState = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final completed = await _onboardingStore.isCompleted();
    if (!mounted) return;
    setState(() {
      _onboardingCompleted = completed;
      _loadingOnboardingState = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seed = Colors.indigo;
    return MaterialApp(
      locale: _locale,
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
              ? const HomeScreen()
              : OnboardingScreen(
                  completionStore: _onboardingStore,
                  onCompleted: () => setState(() => _onboardingCompleted = true),
                ),
    );
  }
}
