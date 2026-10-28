import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoukore_br_matematica/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
    calls.add(call);
    return 1;
  });

  test(
    '読み上げ機能(CLAUDE.md共通要件)がポルトガル語を設定してから'
    '問題文/解説文を読み上げる',
    () async {
      final service = TtsService();
      await service.speak('Quantos lados tem um quadrado?');

      expect(calls.map((c) => c.method), containsAllInOrder(['setLanguage', 'setSpeechRate']));
      final speakCall = calls.firstWhere((c) => c.method == 'speak');
      expect(speakCall.arguments, 'Quantos lados tem um quadrado?');
    },
  );

  test('空文字は読み上げない', () async {
    calls.clear();
    final service = TtsService();
    await service.speak('');
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });
}
