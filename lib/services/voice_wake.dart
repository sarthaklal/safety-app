import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

class VoiceWakeService {
  static PorcupineManager? _porcupineManager;
  static bool isListening = false;  // Prevent multiple initializations

  static Future<void> initialize() async {
    if (isListening) return; // Prevent re-initialization
    isListening = true;

    const String accessKey = "moWtuaeVAlnU/0nUMD+Tx9vJ7aDVDhKpDrmGCkI044eBzl84YcrW3A==";

    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        ["assets/models/safepath_open.ppn"], // ✅ Ensure this path is correct
        _wakeWordDetected,
        sensitivities: [0.5],
      );

      await _porcupineManager!.start();
      print("🎤 Listening for 'SafePath Open' wake word...");
    } on PlatformException catch (e) {
      print("❌ Porcupine initialization error: $e");
    }
  }

  static void _wakeWordDetected(int keywordIndex) {
    print("🎤 Wake word detected! Opening SafePath...");
    openSafePathApp();
  }

  static void openSafePathApp() async {
    print("🚀 SafePath App Opened!");

    final intent = AndroidIntent(
      action: "android.intent.action.MAIN",
      package: "com.example.safepath",
      componentName: "com.example.safepath.MainActivity",
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    await intent.launch();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.microphone,
      Permission.notification, // ✅ Use 'notification' instead of 'accessNotificationPolicy'
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.ignoreBatteryOptimizations,
      Permission.manageExternalStorage, // ✅ Required for accessing files on Android 13+
      Permission.scheduleExactAlarm, // ✅ Needed for scheduling background tasks
    ].request();
  }

  static Future<void> stopListening() async {
    await _porcupineManager?.stop();
  }
}
