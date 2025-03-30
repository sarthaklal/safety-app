import 'dart:async';
import 'dart:math';
import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safepath/utils/voice_command.dart';
import '../../db/db_services.dart';
import '../../model/contacts_model.dart';
import '../../widgets/home_widgets/custom_appbar.dart';
import '../../widgets/home_widgets/custom_carouel.dart';
import '../../widgets/home_widgets/emergency.dart';
import '../../widgets/home_widgets/safe_home/safehome.dart';
import '../../widgets/livesafe.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int qIndex = 1;
  Position? _currentPosition;
  String? _currentAddress;
  LocationPermission? permission;
  late VoiceCommand _voiceCommand;
  final VoiceFeedback _voiceFeedback = VoiceFeedback();

  @override
  void initState() {
    super.initState();
    getRandomQuote();
    _getPermission();
    _getCurrentLocation();
    _voiceCommand = VoiceCommand(onCommandReceived: _processCommand);
    _startListeningContinuously(); // Auto-start voice listening
  }

  /// **🔄 Request SMS Permissions**
  _getPermission() async => await [Permission.sms].request();
  _isPermissionGranted() async => await Permission.sms.isGranted;

  /// **📍 Get User's Current Location**
  Future<void> _getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    _currentAddress =
    "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
  }

  /// **📢 Send Emergency Alert**
  Future<void> _sendEmergencyAlert() async {
    List<TContact> contactList = await DatabaseHelper().getContactList();
    if (contactList.isEmpty) {
      _voiceFeedback.speak("No emergency contacts found.");
      return;
    }

    String message = "Emergency! Please help me at $_currentAddress";

    for (TContact contact in contactList) {
      await BackgroundSms.sendMessage(
          phoneNumber: contact.number, message: message, simSlot: 1);
    }

    _voiceFeedback.speak("Emergency alert sent.");
    Fluttertoast.showToast(msg: "Alert Sent!");
  }

  /// **🎤 Handle Voice Commands**
  void _processCommand(String command) {
    command = command.toLowerCase();

    if (command.contains('help') || command.contains('alert')) {
      _voiceFeedback.speak("Sending emergency alert...");
      _sendEmergencyAlert();
    }
  }

  /// **🎤 Keep Listening Continuously**
  void _startListeningContinuously() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _voiceCommand.startListening();
    });
  }

  /// **📜 Get Random Quote**
  void getRandomQuote() {
    Random rand = Random();
    setState(() {
      qIndex = rand.nextInt(6);
    });
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              quoteIndex: qIndex,
              onTap: getRandomQuote,
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  CustomCarouel(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      localizations!.translate("Emergency"),
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Emergency(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      localizations!.translate("LiveSafe"),
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  LiveSafe(),
                  SafeHome(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
