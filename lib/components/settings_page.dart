import 'package:flutter/material.dart';
import 'package:safepath/components/custom_textfield.dart';
import 'package:safepath/components/primary_button.dart';
import 'package:safepath/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/shared_preference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
  final Function(String) onLanguageChanged;

  const SettingsPage({super.key, required this.onLanguageChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isHelperAvailable = false;
  bool isLoading = false;
  bool On = false;
  final drB = FirebaseDatabase.instance.ref();

  TextEditingController ssidController = TextEditingController();
  TextEditingController pwdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadHelperAvailability();
    loadSafeBandState();
  }

  Future<void> loadSafeBandState() async {
    DatabaseEvent event = await drB.child("Message/MessageSent").once();
    if (event.snapshot.exists) {
      setState(() {
        On = event.snapshot.value as bool;
      });
    }

    // Fetch stored WiFi credentials
    DatabaseEvent ssidEvent = await drB.child("WiFi_Credentials/SSID").once();
    DatabaseEvent pwdEvent = await drB.child("WiFi_Credentials/Password").once();

    if (ssidEvent.snapshot.exists && pwdEvent.snapshot.exists) {
      setState(() {
        ssidController.text = ssidEvent.snapshot.value.toString();
        pwdController.text = pwdEvent.snapshot.value.toString();
      });
    }
  }

  Future<void> loadHelperAvailability() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      String helperId = await SharedPref.getHelperId();
      if (helperId.isNotEmpty) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('helpers')
            .doc(helperId)
            .get();

        if (snapshot.exists) {
          setState(() {
            isHelperAvailable = snapshot.get('available') ?? false;
          });
        }
      }
    } catch (e) {
      // Handle error (show a message or log)
      print("Error loading helper availability: $e");
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> updateHelperAvailability(bool availability) async {
    String helperId = await SharedPref.getHelperId();

    // Immediately update the local state to reflect the switch change
    setState(() {
      isHelperAvailable = availability;
    });

    if (helperId.isNotEmpty) {
      // Update availability in Firestore
      await SharedPref.saveHelperAvailability(availability); // Save availability using SharedPref method
    } else {
      // If no helperId, create a new entry
      DocumentReference ref = await FirebaseFirestore.instance.collection('helpers').add({
        'available': availability,
        'createdAt': Timestamp.now(),
      });

      // Save new helperId in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('helperId', ref.id);

      // Save the availability for the new helper
      await SharedPref.saveHelperAvailability(availability); // Save availability using SharedPref method
    }
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations!.translate("settings")),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(localizations.translate("english")),
            onTap: () async {
              await SharedPref.saveLanguageCode('en');
              widget.onLanguageChanged('en');
            },
          ),
          ListTile(
            title: Text(localizations.translate("hindi")),
            onTap: () async {
              await SharedPref.saveLanguageCode('hi');
              widget.onLanguageChanged('hi');
            },
          ),
          SwitchListTile(
            title: Text('Available as Helper'),
            value: isHelperAvailable,
            onChanged: (value) {
              updateHelperAvailability(value);
            },
          ),
          SwitchListTile(
            title: Text('Use SafeBand'),
            value: On,
            onChanged: (bool value) {
              setState(() {
                On = value;
                drB.child("Message").set({"MessageSent": On});
              });
            },
          ),
          if (On) // Show WiFi fields only when SafeBand is enabled
            Column(
              children: [
                CustomTextField(
                  hintText: 'Enter SSID',
                  controller: ssidController,
                ),
                CustomTextField(
                  hintText: 'Enter Password',
                  controller: pwdController,
                ),
                PrimaryButton(
                  onPressed: () {
                    String ssid = ssidController.text.trim();
                    String pwd = pwdController.text.trim();

                    if (ssid.isNotEmpty && pwd.isNotEmpty) {
                      drB.child("WiFi_Credentials").set({
                        "SSID": ssid,
                        "Password": pwd,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("WiFi details saved successfully")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter both SSID and Password")),
                      );
                    }
                  },
                  title: "Save WiFi",
                ),
              ],
            ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(), // Show loading spinner
            ),
        ],
      ),
    );
  }
}
