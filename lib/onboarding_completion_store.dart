/// オンボーディング（ウェルカム→Ahaモーメント→ペイウォール）を完了済みかどうかを
/// 保持する。永続化先は規定しない（実機では端末内ストレージの実装に差し替える）。
abstract class OnboardingCompletionStore {
  Future<bool> isCompleted();
  Future<void> markCompleted();
}

/// 結合テスト・プロトタイピング用途向けの端末内（プロセス内メモリ）実装。
class InMemoryOnboardingCompletionStore implements OnboardingCompletionStore {
  bool _completed = false;

  @override
  Future<bool> isCompleted() async => _completed;

  @override
  Future<void> markCompleted() async => _completed = true;
}
