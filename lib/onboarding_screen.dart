import 'package:flutter/material.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

import 'l10n/app_localizations.dart';

/// 初回起動時のオンボーディング（ウェルカム→Ahaモーメント→ペイウォール）。
///
/// Ahaモーメントの最初の1問は、カリキュラム連動のQuestionSourceではなく
/// 固定の簡単な問題を使う（最初の1問は必ず正解できる難易度にする方針のため）。
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.completionStore,
    required this.onCompleted,
  });

  final OnboardingCompletionStore completionStore;
  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _ahaTracker = AhaMomentTracker();

  final PageController _pageController = PageController();
  bool _quizCorrect = false;

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
            _WelcomePage(
              l10n: l10n,
              onNext: () => _goToPage(1),
            ),
            _AhaQuizPage(
              l10n: l10n,
              correct: _quizCorrect,
              onAnswered: (correct) => setState(() {
                _quizCorrect = _ahaTracker.reachedOnThisAnswer(
                  alreadyReached: _quizCorrect,
                  correct: correct,
                );
              }),
              onContinue: () => _goToPage(2),
            ),
            _PaywallPage(
              l10n: l10n,
              onStartTrial: _finish,
              onSkip: _finish,
            ),
          ],
        ),
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
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
    required this.onAnswered,
    required this.onContinue,
  });

  final AppLocalizations l10n;
  final bool correct;
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
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    onPressed: correct ? null : () => onAnswered(choice == _correctChoice),
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
                  Icon(Icons.celebration, size: 48, color: theme.colorScheme.primary),
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
          ] else
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

class _PaywallPage extends StatelessWidget {
  const _PaywallPage({
    required this.l10n,
    required this.onStartTrial,
    required this.onSkip,
  });

  final AppLocalizations l10n;
  final VoidCallback onStartTrial;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingPaywallTitle,
            key: const Key('onboardingPaywallTitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingPaywallBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(l10n.onboardingPaywallMonthlyPrice, style: theme.textTheme.titleMedium),
                  Text(l10n.onboardingPaywallYearlyPrice, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingPaywallTrialNote,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboardingStartTrialButton'),
            onPressed: onStartTrial,
            child: Text(l10n.onboardingPaywallStartTrialButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('onboardingSkipButton'),
            onPressed: onSkip,
            child: Text(l10n.onboardingPaywallSkipButton),
          ),
        ],
      ),
    );
  }
}
