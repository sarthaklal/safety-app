import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:safepath/utils/constants.dart';

import '../../components/custom_textfield.dart';
import '../../components/heatmap.dart';
import '../../components/primary_button.dart';
import '../../components/secondary_button.dart';
import '../../l10n/app_localizations.dart'; // Import the Heatmap Screen

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  TextEditingController locationC = TextEditingController();
  TextEditingController viewsC = TextEditingController();
  bool isSaving = false;
  final String googleApiKey = geocodingApi;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationAndFetchIncidents();
    checkUnsafeArea();
  }

  /// **📍 Fetch User Location & Crime Incidents**
  Future<void> _fetchCurrentLocationAndFetchIncidents() async {
    Position position = await _getCurrentLocation();
    _currentPosition = position;
    String city = await _getCityFromCoordinates(position.latitude, position.longitude);
    fetchCrimeIncidents(city, position.latitude, position.longitude);
  }

  /// **📍 Get User's Current Location**
  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// **📍 Get City Name from Coordinates**
  Future<String> _getCityFromCoordinates(double lat, double lng) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        return data['results'][0]['address_components'][2]['long_name'];
      }
    }
    return "Unknown Location";
  }

  /// **🔍 Fetch 5 Crime Incidents from News**
  Future<void> fetchCrimeIncidents(String city, double lat, double lng) async {
    final url = 'https://gnews.io/api/v4/search?q=$city%20crime&token=280c5e3bd9fb712febe106255a10fb30&lang=en&max=5';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final newsData = jsonDecode(response.body);
      List articles = newsData['articles'];

      for (var article in articles) {
        String title = article['title'];
        String description = article['description'];

        await FirebaseFirestore.instance.collection('reviews').add({
          'location': city,
          'views': "$title - $description",
          'latitude': lat,
          'longitude': lng
        });
      }
    } else {
      print("❌ Error fetching crime news");
    }
  }

  /// **⚠️ Check If User is Near Unsafe Area**
  Future<void> checkUnsafeArea() async {
    final unsafeAreas = await FirebaseFirestore.instance.collection('reviews').get();

    for (var doc in unsafeAreas.docs) {
      final unsafeLocation = doc.data();
      final unsafeLat = unsafeLocation['latitude'];
      final unsafeLng = unsafeLocation['longitude'];
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, unsafeLat, unsafeLng);
      if (distance < 500) { // 500 meters threshold
        showAlertDialog(context, unsafeLocation['location']);
        break;
      }
    }
  }

  /// **⚠️ Show Alert If Near Unsafe Area**
  void showAlertDialog(BuildContext context, String areaName) {
    var localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(localizations!.translate("Unsafe Area Alert!")),
        content: Text(localizations.translate("near_unsafe_area", args: {'areaName': areaName})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(localizations.translate("OK"))),
        ],
      ),
    );
  }

  Future<void> saveReviews() async {
    setState(() {
      isSaving = true;
    });

    final coordinates = await _getCurrentLocation();

    await FirebaseFirestore.instance.collection('reviews').add({
      'location': locationC.text,
      'views': viewsC.text,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
    }).then((_) {
      setState(() {
        isSaving = false;
        Fluttertoast.showToast(msg: 'Review Saved');
      });
    }).catchError((error) {
      setState(() {
        isSaving = false;
      });
      Fluttertoast.showToast(msg: 'Failed to save review');
    });
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Scaffold(
      body: isSaving
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            Text(
              localizations!.translate("Unsafe Areas Reported"),
              style: TextStyle(fontSize: 30),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index];
                      return Card(
                        elevation: 5,
                        child: ListTile(
                          title: Text(data['location']),
                          subtitle: Text(data['views']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Floating Button for Adding Reviews
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.purpleAccent,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(localizations!.translate("Report an Unsafe Area")),
                    content: Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomTextField(
                              hintText: localizations.translate("Enter location"),
                              controller: locationC,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomTextField(
                              hintText: localizations.translate("Enter reason for marking as unsafe"),
                              controller: viewsC,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      PrimaryButton(
                        onPressed: () {
                          saveReviews();
                          Navigator.pop(context);
                        },
                        title: localizations.translate("Save"),
                      ),
                      SecondaryButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        title: localizations.translate("Cancel"),
                      ),
                    ],
                  ),
                );
              },
              child: Icon(Icons.add),
            ),
          ),
          // Floating Button for Heatmap
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HeatmapScreen()), // Navigate to Heatmap Screen
                );
              },
              child: Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }
}
