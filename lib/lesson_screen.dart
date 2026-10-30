import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'lesson_content.dart';
import 'unit_name_resolver.dart';

/// 単元を解く前に読む、教科書的な「学ぶ」画面。導入文→コツ→解いてみよう
/// (例題1問、問題→答え→解説の順でタップして段階的に開く)という構成にし、
/// 教科書をただ転載するのではなく、段階的に読み進められるようにする。
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.unitId, required this.lesson});

  final String unitId;
  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _answerRevealed = false;
  bool _explanationRevealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lesson = widget.lesson;

    return Scaffold(
      appBar: AppBar(title: Text(resolveUnitName(l10n, widget.unitId))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                lesson.intro,
                key: const Key('lessonIntroText'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(l10n.lessonTipLabel, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(lesson.tip, key: const Key('lessonTipText')),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.lessonExampleTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.example.question,
                    key: const Key('lessonExampleQuestionText'),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  if (!_answerRevealed)
                    OutlinedButton(
                      key: const Key('lessonRevealAnswerButton'),
                      onPressed: () => setState(() => _answerRevealed = true),
                      child: Text(l10n.lessonRevealAnswerButton),
                    )
                  else ...[
                    Text(
                      lesson.example.answer,
                      key: const Key('lessonExampleAnswerText'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_explanationRevealed)
                      OutlinedButton(
                        key: const Key('lessonRevealExplanationButton'),
                        onPressed: () => setState(() => _explanationRevealed = true),
                        child: Text(l10n.lessonRevealExplanationButton),
                      )
                    else
                      Text(
                        lesson.example.explanation,
                        key: const Key('lessonExampleExplanationText'),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('lessonBackToPracticeButton'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.lessonBackToPracticeButton),
          ),
        ],
      ),
    );
  }
}
