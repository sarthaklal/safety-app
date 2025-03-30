import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:safepath/utils/constants.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final locationController = Location();
  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref("users/sender/location"); // ✅ Change this if needed

  LatLng? senderPosition; // Live location from Firebase
  LatLng? receiverPosition; // Receiver's location from device GPS

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => await initializeMap());
  }

  Future<void> initializeMap() async {
    await fetchReceiverLocation();
    fetchSenderLocationFromFirebase();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: senderPosition == null || receiverPosition == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
      initialCameraPosition: CameraPosition(
        target: senderPosition!, // Start map centered on sender
        zoom: 13,
      ),
      markers: {
        if (senderPosition != null)
          Marker(
            markerId: const MarkerId('senderLocation'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            position: senderPosition!,
          ),
        if (receiverPosition != null)
          Marker(
            markerId: const MarkerId('receiverLocation'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue),
            position: receiverPosition!,
          ),
      },
      polylines: Set<Polyline>.of(polylines.values),
    ),
  );

  /// Fetches the **receiver's location** from the device
  Future<void> fetchReceiverLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    LocationData currentLocation = await locationController.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      setState(() {
        receiverPosition = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
      });
    }
  }

  /// Listens to Firebase for **sender's live location updates**
  void fetchSenderLocationFromFirebase() {
    dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data["latitude"] != null && data["longitude"] != null) {
          setState(() {
            senderPosition = LatLng(data["latitude"], data["longitude"]);
          });

          if (receiverPosition != null) {
            fetchPolylinePoints(); // Draw route when both locations are available
          }
        }
      }
    });
  }

  /// Fetches polyline between sender and receiver
  Future<void> fetchPolylinePoints() async {
    if (senderPosition == null || receiverPosition == null) return;

    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: geocodingApi,
      request: PolylineRequest(
        origin: PointLatLng(senderPosition!.latitude, senderPosition!.longitude),
        destination:
        PointLatLng(receiverPosition!.latitude, receiverPosition!.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      final polylineCoordinates = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      generatePolyLineFromPoints(polylineCoordinates);
    } else {
      debugPrint(result.errorMessage);
    }
  }

  /// Draws a polyline on the map
  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() => polylines[id] = polyline);
  }
}
