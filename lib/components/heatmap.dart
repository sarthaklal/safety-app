import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  List<LatLng> heatmapPoints = [];
  LatLng _userLocation = const LatLng(13.0843, 80.2705); // Default location

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _fetchUnsafeLocations();
  }

  /// **📍 Get User's Current Location**
  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return; // Exit if permission is denied
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_userLocation, 12),
    );
  }

  /// **🔍 Fetch Unsafe Locations from Firestore**
  Future<void> _fetchUnsafeLocations() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('reviews').get();

    List<LatLng> points = [];
    Set<Marker> newMarkers = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        double lat = data['latitude'];
        double lng = data['longitude'];

        LatLng position = LatLng(lat, lng);
        points.add(position);

        // Add markers for visualization
        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(
              title: data['location'],
              snippet: data['views'] ?? "Unsafe area reported",
            ),
          ),
        );
      }
    }

    setState(() {
      heatmapPoints = points;
      _markers = newMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Unsafe Areas Heatmap")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _userLocation, // Default to user's location
          zoom: 12,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: _markers,
        circles: heatmapPoints.map((point) {
          return Circle(
            circleId: CircleId(point.toString()),
            center: point,
            radius: 300, // Heatmap effect radius
            fillColor: Colors.red.withOpacity(0.3),
            strokeWidth: 0,
          );
        }).toSet(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          _getUserLocation(); // Refresh user location
          _fetchUnsafeLocations(); // Refresh heatmap data
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
