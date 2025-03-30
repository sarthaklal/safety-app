import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static SharedPreferences? _preferences;

  static String helperId = FirebaseAuth.instance.currentUser!.uid;

  static const String keyHelperId = 'helperId'; // Key for storing helper ID
  static const String keyUserType = 'userType';
  static const String keyLanguageCode = 'selected_language';

  // Initialize SharedPreferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Save the helper's availability to Firestore and SharedPreferences
  static Future<void> saveHelperAvailability(bool isAvailable) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    DateTime now = DateTime.now();  // Current date and time

    // Save the data to Firestore
    await FirebaseFirestore.instance
        .collection('helpers')
        .doc(helperId) // Use the helper's UID here
        .set({
      'isAvailable': isAvailable,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updatedAt': Timestamp.fromDate(now),  // Store the last update time
      'createdAt': FieldValue.serverTimestamp(),  // Automatically set the server timestamp
    }, SetOptions(merge: true)); // Merge to keep existing data
  }

  // Save helper ID to SharedPreferences
  static Future<void> saveHelperId(String helperId) async {
    await _preferences!.setString(keyHelperId, helperId);
  }

  // Get the saved helper ID from SharedPreferences
  static Future<String> getHelperId() async {
    return _preferences!.getString(keyHelperId) ?? ''; // Return empty string if not found
  }

  // Save user type to SharedPreferences
  static Future<void> saveUserType(String type) async {
    await _preferences!.setString(keyUserType, type);
  }

  // Get the user type from SharedPreferences
  static Future<String?> getUserType() async {
    return _preferences!.getString(keyUserType);
  }

  // Save the language code to SharedPreferences
  static Future<void> saveLanguageCode(String languageCode) async {
    await _preferences!.setString(keyLanguageCode, languageCode);
  }

  // Get the language code from SharedPreferences
  static Future<String?> getLanguageCode() async {
    return _preferences!.getString(keyLanguageCode);
  }
}
