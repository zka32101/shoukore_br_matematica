import 'package:flutter_tts/flutter_tts.dart';

/// 読み上げ機能（CLAUDE.md共通要件「読み上げ機能あり」）。問題文・解説文を
/// ポルトガル語(pt-BR)で読み上げる。実機のTTSエンジンに依存するため、
/// ウィジェットテスト環境ではメソッドチャンネルをモックして検証する。
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.45);
    _initialized = true;
  }

  /// [text]を読み上げる。先に再生中のものがあれば止めてから話し始める。
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _ensureInitialized();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
