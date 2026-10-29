import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/explanation_resolver.dart';
import 'package:shoukore_br_matematica/l10n/app_localizations.dart';
import 'package:shoukore_br_matematica/question_prompt_resolver.dart';
import 'package:shoukore_core_global/shoukore_core_global.dart';

/// コンテンツレビューで指摘された「algebra/geometria/probabilidadeの
/// テンプレート不足」「文章題の場面の多様性不足」への対応で追加した
/// 新規シナリオ(スポーツ・家族行事テーマ)が、出題文・解説文として
/// 正しく解決されることを確認する。
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pt', 'BR'));
  });

  test('新規シーケンスシナリオの出題文が解決される', () {
    for (final scenarioId in [
      'scenario_jumprope',
      'scenario_family_table',
      'scenario_soccer_training',
    ]) {
      final question = Question(
        id: 'q_test',
        unitId: 'mat_algebra_1',
        type: QuestionType.choice,
        difficulty: 0,
        choices: const ['1', '2'],
        answer: '1',
        explanationId: 'explanation_sequence',
        params: {'terms': '1,2,3', 'scenarioId': scenarioId},
      );
      final prompt = resolveQuestionPrompt(l10n, question);
      expect(prompt, isNotNull, reason: scenarioId);
      expect(prompt, isNot(l10n.sequencePrompt('1, 2, 3')), reason: scenarioId);
    }
  });

  test('新規図形シナリオの出題文が解決される', () {
    final kiteQuestion = Question(
      id: 'q_test',
      unitId: 'mat_geometria_1',
      type: QuestionType.choice,
      difficulty: 0,
      choices: const ['4'],
      answer: '4',
      explanationId: 'explanation_shape_square',
      params: {'shapeNameKey': 'shape_square', 'scenarioId': 'scenario_kite'},
    );
    expect(resolveQuestionPrompt(l10n, kiteQuestion), contains('pipa'));

    final playgroundQuestion = Question(
      id: 'q_test',
      unitId: 'mat_geometria_5',
      type: QuestionType.choice,
      difficulty: 0,
      choices: const ['20'],
      answer: '20',
      explanationId: 'explanation_diagonals',
      params: {
        'shapeNameKey': 'shape_octagon',
        'questionKind': 'diagonals',
        'scenarioId': 'scenario_playground',
      },
    );
    expect(resolveQuestionPrompt(l10n, playgroundQuestion), contains('parquinho'));
  });

  test('新規データ分析シナリオの出題文が解決される', () {
    final tripQuestion = Question(
      id: 'q_test',
      unitId: 'mat_probabilidade_2',
      type: QuestionType.choice,
      difficulty: 0,
      choices: const ['10'],
      answer: '10',
      explanationId: 'explanation_dataset_sum',
      params: {'values': '1,2,3', 'operation': 'sum', 'scenarioId': 'scenario_family_trip'},
    );
    expect(resolveQuestionPrompt(l10n, tripQuestion), contains('viagem'));

    final relayQuestion = Question(
      id: 'q_test',
      unitId: 'mat_probabilidade_5',
      type: QuestionType.choice,
      difficulty: 0,
      choices: const ['5'],
      answer: '5',
      explanationId: 'explanation_dataset_range',
      params: {'values': '1,2,3', 'operation': 'range', 'scenarioId': 'scenario_relay'},
    );
    expect(resolveQuestionPrompt(l10n, relayQuestion), contains('revezamento'));
  });

  test('拡充した単元が使う解説IDは全てl10nに存在する', () {
    for (final explanationId in [
      'explanation_sequence',
      'explanation_sequence_descending',
      'explanation_sequence_multiplicative',
      'explanation_shape_square',
      'explanation_diagonals',
      'explanation_dataset_sum',
      'explanation_dataset_range',
    ]) {
      expect(resolveExplanation(l10n, explanationId), isNotNull, reason: explanationId);
    }
  });
}
