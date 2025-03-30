import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommand {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final Function(String) onCommandReceived;

  VoiceCommand({required this.onCommandReceived}) {
    _speech = stt.SpeechToText();
  }

  /// **🎤 Start Listening for Commands**
  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('Status: $val'),
      onError: (val) => print('Error: $val'),
    );

    if (available) {
      _isListening = true;
      _speech.listen(
        onResult: (val) {
          String command = val.recognizedWords;
          onCommandReceived(command);
          stopListening();
        },
      );
    }
  }

  /// **🛑 Stop Listening**
  void stopListening() {
    _speech.stop();
    _isListening = false;
  }
}

class VoiceFeedback {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}
