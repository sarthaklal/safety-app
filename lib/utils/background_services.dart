import 'dart:async';
import 'dart:ui';
import 'package:background_sms/background_sms.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:safepath/shake.dart';
import 'package:vibration/vibration.dart';

import '../db/db_services.dart';
import '../model/contacts_model.dart';

final AudioPlayer _audioPlayer = AudioPlayer();
final FlutterTts _flutterTts = FlutterTts();
final stt.SpeechToText _speech = stt.SpeechToText();
final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

/// **🌟 Initialize Background Service**
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'SafePath',
    'Foreground Service',
    importance: Importance.high,
    description: 'SafePath is monitoring for emergencies.',
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true, // ✅ Keeps running even after app close
      autoStartOnBoot: true, // ✅ Restarts on device boot
      notificationChannelId: 'SafePath',
      initialNotificationTitle: 'SafePath Running',
      initialNotificationContent: 'Monitoring for emergencies...',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );

  service.startService();
}

/// **🏃 Background Service Function (Runs Shake + Voice + Notifications)**
@pragma('vm-entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  notificationsPlugin.initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    ),
  );

  notificationsPlugin.show(
    999,
    "SafePath",
    "Listening for emergencies...",
    NotificationDetails(
      android: AndroidNotificationDetails(
        "SafePath",
        "Foreground service",
        icon: 'ic_bg_service_small',
        ongoing: true,
      ),
    ),
  );

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // ✅ Corrected Foreground Service Handling
    service.setAsForegroundService();
  }

  // 🔹 Start Shake + Voice Detection
  _getCurrentLocation();
  _startListeningContinuously();
  _startShakeDetection();
}


/// **🔹 Request Necessary Permissions**
Future<void> requestPermissions() async {
  await [
    Permission.sms,
    Permission.microphone,
    Permission.locationAlways,
    Permission.locationWhenInUse,
    Permission.ignoreBatteryOptimizations, // ✅ Allows app to run in the background
  ].request();

  // ✅ Ask user to disable battery optimizations
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    openAppSettings();
  }
}

/// **📍 Get Current Location**
Position? _currentPosition;

void _getCurrentLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: 'Location permission permanently denied');
      return;
    }
  }

  Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      forceAndroidLocationManager: true)
      .then((Position position) {
    _currentPosition = position;
  });
}

/// **🚨 Send Emergency SMS**
Future<void> sendAlert() async {
  if (_currentPosition == null) {
    Fluttertoast.showToast(msg: 'Location not available');
    return;
  }

  List<TContact> contactList = await DatabaseHelper().getContactList();
  if (contactList.isEmpty) {
    _speak("No emergency contacts found.");
    return;
  }

  String message =
      "🚨 Emergency! Help needed at: https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}";

  if (await Permission.sms.isGranted) {
    for (TContact contact in contactList) {
      await BackgroundSms.sendMessage(
          phoneNumber: contact.number, message: message, simSlot: 1);
    }
    _speak("Emergency alert sent.");
    Fluttertoast.showToast(msg: 'Emergency SMS sent!');
  } else {
    Fluttertoast.showToast(msg: 'SMS permission denied');
  }
}

/// **🔊 Play Emergency Siren**
void playSiren() async {
  await _audioPlayer.setAsset('assets/siren.mp3');
  _audioPlayer.play();
  _audioPlayer.setVolume(2.0);
}

/// **🗣️ Voice Feedback**
void _speak(String text) async {
  await _flutterTts.speak(text);
}

/// **🎤 Start Continuous Voice Listening**
void _startListeningContinuously() {
  Timer.periodic(Duration(seconds: 10), (timer) { // ✅ Checks every 10 sec
    _listenForCommands();
  });
}

/// **🎤 Listen for Voice Commands (Background Listening)**
void _listenForCommands() async {
  bool available = await _speech.initialize(
    onStatus: (val) => print('Status: $val'),
    onError: (val) => print('Error: $val'),
  );

  if (available) {
    _speech.listen(
      onResult: (val) {
        String command = val.recognizedWords.toLowerCase();
        if (command.contains("help") || command.contains("alert")) {
          _speak("Emergency alert triggered.");
          sendAlert();
        }
      },
    );
  }
}

/// **📱 Shake Detection (Works in Background)**
void _startShakeDetection() {
  ShakeDetector.autoStart(
    shakeThresholdGravity: 2.7,
    onPhoneShake: (shakeCount) async {
      if (shakeCount == 2) {
        sendAlert();
      } else if (shakeCount == 3) {
        playSiren();
      }
    },
  );
}

/// **🔔 Send Periodic Notifications Every 1 Minute**
void _sendPeriodicNotifications() {
  Timer.periodic(Duration(minutes: 1), (timer) { // ✅ Sends a notification every minute
    notificationsPlugin.show(
      1000,
      "SafePath Monitoring",
      "SafePath is running in the background, monitoring your safety.",
      NotificationDetails(
        android: AndroidNotificationDetails(
          "SafePath",
          "Background Service",
          icon: 'ic_bg_service_small',
          importance: Importance.high,
          ongoing: true,
        ),
      ),
    );
  });
}
