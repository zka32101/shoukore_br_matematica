import 'package:flutter/widgets.dart';

/// 選択した表示言語の保存先を抽象化する（CLAUDE.md共通要件
/// 「第二言語に英語も選択できる」対応）。他のStore(ConsentStore等)と同じ
/// 設計方針で、既定実装は端末内保存ではなくメモリ上のみ
/// (`InMemoryLocalePreferenceStore`)。永続化が必要になったら、同じ
/// インターフェースのまま実装を差し替える。
abstract class LocalePreferenceStore {
  Future<Locale?> getLocale();

  Future<void> setLocale(Locale locale);
}

class InMemoryLocalePreferenceStore implements LocalePreferenceStore {
  Locale? _locale;

  @override
  Future<Locale?> getLocale() async => _locale;

  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
  }
}
