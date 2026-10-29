import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';
import 'package:shoukore_core_global/shoukore_core_global_entitlement_revenuecat.dart';

import 'age_gate_consent_logic.dart';
import 'curriculum_repository.dart';
import 'l10n/app_localizations.dart';

/// 初回起動時のオンボーディング（ウェルカム→年齢確認/保護者同意→
/// Ahaモーメント→ペイウォール）。
///
/// 年齢確認・保護者同意（LGPD第14条・ECA Digital対応）は、設定画面から
/// 任意で訪れるだけでは実質誰も通らないため、オンボーディングの必須
/// ステップとして組み込む（スキップボタンは置かない）。
///
/// Ahaモーメントの最初の1問は、カリキュラム連動のQuestionSourceではなく
/// 固定の簡単な問題を使う（最初の1問は必ず正解できる難易度にする方針のため）。
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.completionStore,
    required this.onCompleted,
    required this.consentStore,
    this.entitlementReader,
  });

  final OnboardingCompletionStore completionStore;
  final VoidCallback onCompleted;

  /// ホーム画面の設定タイルと同じ同意記録を共有するため、アプリ直下から
  /// 渡される単一インスタンス。
  final ConsentStore consentStore;

  /// RevenueCat APIキー未設定（開発中・CI）の場合はnullのままにする。
  /// nullの場合、ペイウォールは実際のOffering取得を試みず、固定の価格表示＋
  /// スキップのみのフォールバック表示になる。
  final RevenueCatEntitlementReader? entitlementReader;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _ahaTracker = AhaMomentTracker();
  static const _repository = CurriculumRepository();
  static const _clock = SystemClock();
  static const _locale = Locale('pt', 'BR');

  final PageController _pageController = PageController();
  bool _quizCorrect = false;
  bool _quizAnswered = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await widget.completionStore.markCompleted();
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _WelcomePage(l10n: l10n, onNext: () => _goToPage(1)),
            _AgeGatePage(
              l10n: l10n,
              repository: _repository,
              clock: _clock,
              locale: _locale,
              consentStore: widget.consentStore,
              onNext: () => _goToPage(2),
            ),
            _AhaQuizPage(
              l10n: l10n,
              correct: _quizCorrect,
              answered: _quizAnswered,
              onAnswered: (correct) => setState(() {
                _quizAnswered = true;
                _quizCorrect = _ahaTracker.reachedOnThisAnswer(
                  alreadyReached: _quizCorrect,
                  correct: correct,
                );
              }),
              onContinue: () => _goToPage(3),
            ),
            _PaywallPage(
              l10n: l10n,
              entitlementReader: widget.entitlementReader,
              onPurchased: (_) => _finish(),
              onSkip: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

/// 必須の年齢確認/保護者同意ステップ。生年を入力させ、地域の同意年齢
/// (`RegionalProfile.ageOfConsent`)未満なら保護者同意の質問を続けて表示する。
/// どちらの場合も同意状態を記録してから次に進む（スキップ不可）。
class _AgeGatePage extends StatefulWidget {
  const _AgeGatePage({
    required this.l10n,
    required this.repository,
    required this.clock,
    required this.locale,
    required this.consentStore,
    required this.onNext,
  });

  final AppLocalizations l10n;
  final CurriculumRepository repository;
  final Clock clock;
  final Locale locale;
  final ConsentStore consentStore;
  final VoidCallback onNext;

  @override
  State<_AgeGatePage> createState() => _AgeGatePageState();
}

class _AgeGatePageState extends State<_AgeGatePage> {
  final TextEditingController _birthYearController = TextEditingController();
  String? _errorText;
  bool _submitting = false;

  // nullは「まだ生年未確定」、trueなら保護者同意の質問を表示する。
  bool? _consentStepNeeded;

  @override
  void dispose() {
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _submitBirthYear() async {
    final birthYear = int.tryParse(_birthYearController.text);
    final currentYear = widget.clock.now().year;
    if (birthYear == null || birthYear < 1900 || birthYear > currentYear) {
      setState(() => _errorText = widget.l10n.ageGateInvalidYearError);
      return;
    }
    setState(() {
      _errorText = null;
      _submitting = true;
    });
    final profile = await widget.repository.loadRegionalProfile(widget.locale);
    final requiresConsent = await requiresConsentAndRecordIfNot(
      birthYear: birthYear,
      profile: profile,
      clock: widget.clock,
      consentStore: widget.consentStore,
    );
    if (!mounted) return;
    if (!requiresConsent) {
      widget.onNext();
      return;
    }
    setState(() {
      _submitting = false;
      _consentStepNeeded = true;
    });
  }

  Future<void> _answerConsent(bool accepted) async {
    await recordConsentAnswer(
      consentStore: widget.consentStore,
      clock: widget.clock,
      accepted: accepted,
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    if (_consentStepNeeded == true) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.consentTitle,
              key: const Key('onboardingConsentTitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.consentBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('onboardingConsentAcceptButton'),
              onPressed: () => _answerConsent(true),
              child: Text(l10n.consentAcceptButton),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('onboardingConsentDeclineButton'),
              onPressed: () => _answerConsent(false),
              child: Text(l10n.consentDeclineButton),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n.ageGateTitle,
            key: const Key('onboardingAgeGateTitle'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('onboardingBirthYearField'),
            controller: _birthYearController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.ageGateBirthYearHint,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboardingAgeGateConfirmButton'),
            onPressed: _submitting ? null : _submitBirthYear,
            child: Text(l10n.ageGateConfirmButton),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.l10n, required this.onNext});

  final AppLocalizations l10n;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.egg_outlined, size: 56),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWelcomeTitle,
            key: const Key('onboardingWelcomeTitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingWelcomeBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('onboardingWelcomeNextButton'),
            onPressed: onNext,
            child: Text(l10n.onboardingWelcomeNextButton),
          ),
        ],
      ),
    );
  }
}

class _AhaQuizPage extends StatelessWidget {
  const _AhaQuizPage({
    required this.l10n,
    required this.correct,
    required this.answered,
    required this.onAnswered,
    required this.onContinue,
  });

  final AppLocalizations l10n;
  final bool correct;
  final bool answered;
  final ValueChanged<bool> onAnswered;
  final VoidCallback onContinue;

  // 最初のAhaモーメント用の固定問題。必ず正解できる難易度にするため、
  // カリキュラム連動の問題生成は使わず、ここで選択肢を固定する。
  static const _choices = [4, 5, 6, 7];
  static const _correctChoice = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingQuizTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingQuizQuestion,
            key: const Key('onboardingQuizQuestionText'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final choice in _choices)
                SizedBox(
                  width: 72,
                  height: 56,
                  child: ElevatedButton(
                    key: Key('onboardingQuizChoice_$choice'),
                    onPressed: correct
                        ? null
                        : () => onAnswered(choice == _correctChoice),
                    child: Text('$choice'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (correct) ...[
            AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingQuizCorrectFeedback,
                    key: const Key('onboardingQuizFeedbackText'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('onboardingQuizContinueButton'),
              onPressed: onContinue,
              child: Text(l10n.onboardingQuizContinueButton),
            ),
          ] else if (answered)
            Text(
              l10n.onboardingQuizIncorrectFeedback,
              key: const Key('onboardingQuizFeedbackText'),
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _PaywallPage extends StatefulWidget {
  const _PaywallPage({
    required this.l10n,
    required this.entitlementReader,
    required this.onPurchased,
    required this.onSkip,
  });

  final AppLocalizations l10n;
  final RevenueCatEntitlementReader? entitlementReader;
  final ValueChanged<Entitlement> onPurchased;
  final VoidCallback onSkip;

  @override
  State<_PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<_PaywallPage> {
  Offering? _offering;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (widget.entitlementReader == null) return;
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) setState(() => _offering = offerings.current);
    } catch (_) {
      // RevenueCat未設定・取得失敗時は固定の価格表示＋スキップのみに
      // フォールバックする（下のbuildでofferingがnullの場合の表示）。
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _purchasing = true);
    try {
      final entitlement = await widget.entitlementReader!.purchasePackage(
        package,
      );
      widget.onPurchased(entitlement);
    } catch (_) {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final packages = _offering?.availablePackages ?? const <Package>[];
    return Padding(
      padding: const EdgeInsets.all(24),
      // 要点リストを追加して内容が増えたため、画面が小さい端末でも
      // RenderFlexオーバーフローにならないようスクロール可能にする。
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingPaywallTitle,
              key: const Key('onboardingPaywallTitle'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingPaywallBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            // 「広告なし」「14日間すべて利用可能」など、児童の保護者が購入判断
            // しやすいよう要点を一目で分かるリスト形式で示す。
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final benefit in [
                    l10n.onboardingPaywallBenefitNoAds,
                    l10n.onboardingPaywallBenefitFullTrial,
                    l10n.onboardingPaywallBenefitReports,
                    l10n.onboardingPaywallBenefitScreenTime,
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (packages.isNotEmpty)
              Column(
                children: [
                  for (final package in packages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton(
                        key: Key(
                          'onboardingPurchasePackage_${package.identifier}',
                        ),
                        onPressed: _purchasing
                            ? null
                            : () => _purchase(package),
                        child: Text(
                          '${package.storeProduct.title} - ${package.storeProduct.priceString}',
                        ),
                      ),
                    ),
                ],
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        l10n.onboardingPaywallMonthlyPrice,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        l10n.onboardingPaywallYearlyPrice,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.onboardingPaywallTrialNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (packages.isEmpty)
              FilledButton(
                key: const Key('onboardingStartTrialButton'),
                // Offeringが取得できない場合（RevenueCat未設定・開発中・CI）は
                // 購入フローへ進めないため、押しても従来通りスキップ扱いにする。
                onPressed: widget.onSkip,
                child: Text(l10n.onboardingPaywallStartTrialButton),
              ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('onboardingSkipButton'),
              onPressed: widget.onSkip,
              child: Text(l10n.onboardingPaywallSkipButton),
            ),
          ],
        ),
      ),
    );
  }
}
