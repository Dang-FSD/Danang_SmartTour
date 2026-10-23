import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class VoiceHandoffHelper {
  /// Phát âm thông điệp cảnh báo bằng Tiếng Việt (Web Speech Synthesis API)
  static void speakVietnamese(String text) {
    if (kIsWeb) {
      try {
        final sanitized = text.replaceAll("'", "\\'").replaceAll('\n', ' ');
        final jsCode = '''
          if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
            var utterance = new SpeechSynthesisUtterance('$sanitized');
            utterance.lang = 'vi-VN';
            utterance.rate = 0.9;
            utterance.pitch = 1.0;
            window.speechSynthesis.speak(utterance);
          } else {
            console.log('Speech synthesis not supported');
          }
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (e) {
        debugPrint('Voice handoff web error: $e');
      }
    } else {
      debugPrint('[VoiceHandoff] Mobile platform speech stub: $text');
    }
  }

  static void stop() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ["if ('speechSynthesis' in window) { window.speechSynthesis.cancel(); }"]);
      } catch (_) {}
    }
  }
}
