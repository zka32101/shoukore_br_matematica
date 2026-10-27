import 'package:shoukore_core_global/shoukore_core_global.dart';

/// `WeeklyReportBuilder`はAttemptのquestionIdからQuestion（misconceptionTags参照用）を
/// 引けるルックアップ関数を要求するが、`QuestionSource`は生成した問題を保持しない。
/// サンプルアプリでは出題時にここへ登録し、週次レポート集計時に引く。
/// 本番アプリでは`ProgressStore`実装側（drift等）に問題スナップショットを
/// 保存する設計にするのが望ましい。
class QuestionCache {
  final Map<String, Question> _byId = {};

  void register(Question question) {
    _byId[question.id] = question;
  }

  Question lookup(String questionId) {
    final question = _byId[questionId];
    if (question != null) return question;
    // 旧セッションの問題などキャッシュに無い場合は、誤解タグ無しの空問題として扱う。
    return Question(
      id: questionId,
      unitId: '',
      type: QuestionType.choice,
      difficulty: 0.5,
      choices: const [],
      answer: '',
      explanationId: '',
    );
  }
}
