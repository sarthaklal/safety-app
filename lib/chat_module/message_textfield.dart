import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as newlocation;
import 'package:safepath/utils/constants.dart';
import 'package:uuid/uuid.dart';

class MessageTextfield extends StatefulWidget {
  final String currentId;
  final String friendId;

  const MessageTextfield(
      {super.key, required this.currentId, required this.friendId});

  @override
  State<MessageTextfield> createState() => _MessageTextfieldState();
}

class _MessageTextfieldState extends State<MessageTextfield> {
  TextEditingController _controller = TextEditingController();
  Position? _currentPosition;
  String? _currentAddress;
  String? message;
  LocationPermission? permission;
  File? imageFile;
  newlocation.Location location = newlocation.Location();
  newlocation.LocationData? _currentLocation;
  bool _sentLocation = false;

  Future getImage() async {
    ImagePicker picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 50).then((XFile? xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      Placemark place = placemarks[0];
      return "${place.street}, ${place.locality}, ${place.postalCode}";
    } catch (e) {
      return "Unknown Location";
    }
  }

  Future getImageFromCamera() async {
    ImagePicker picker = ImagePicker();
    await picker.pickImage(source: ImageSource.camera, imageQuality: 50).then((XFile? xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = Uuid().v1();
    int status = 1;
    var ref =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");
    var uploadTask = await ref.putFile(imageFile!);
    if (status == 1) {
      String imgUrl = await uploadTask.ref.getDownloadURL();
      await sendMessage(imgUrl, 'img');
    }
  }

  Future _getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      Fluttertoast.showToast(msg: 'Location permission denied');
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(msg: 'Location permission permanently denied');
      }
    }
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        print(_currentPosition!.latitude);
        _getAddressFromLatLon();
      });
    }).catchError((e) {
    });
  }

  _getAddressFromLatLon() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            "${place.street},${place.locality},${place.postalCode},";
      });
    } catch (e) {
    }
  }

  void _startUpdatingLocation() async {
    bool serviceEnabled;
    newlocation.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == newlocation.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != newlocation.PermissionStatus.granted) return;
    }

    // Start updating the location in real-time
    location.onLocationChanged.listen((newlocation.LocationData currentLocation) async {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentLocation = currentLocation;
        });

        _currentAddress = await _getAddressFromCoordinates(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!
        );

        DatabaseReference locationRef = FirebaseDatabase.instance.ref("users/${widget.currentId}/location");
        await locationRef.set({
          "latitude": _currentLocation!.latitude,
          "longitude": _currentLocation!.longitude,
          "accuracy": _currentLocation!.accuracy ?? 0.0,
          "altitude": _currentLocation!.altitude ?? 0.0,
          "heading": _currentLocation!.heading ?? 0.0,
          "speed": _currentLocation!.speed ?? 0.0,
          "address": _currentAddress,
          "timestamp": ServerValue.timestamp,
        });
      }
    });
  }


  sendMessage(String message, String type) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentId)
        .collection('messages')
        .doc(widget.friendId)
        .collection('chats')
        .add({
      'senderId': widget.currentId,
      'receiverId': widget.friendId,
      'message': message,
      'type': type,
      'date': DateTime.now(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendId)
        .collection('messages')
        .doc(widget.currentId)
        .collection('chats')
        .add({
      'senderId': widget.currentId,
      'receiverId': widget.friendId,
      'message': message,
      'type': type,
      'date': DateTime.now(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(1.0),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                cursorColor: primaryColor,
                controller: _controller,
                decoration: InputDecoration(
                    hintText: 'Type your message',
                    fillColor: Colors.grey[100],
                    filled: true,
                    prefixIcon: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (context) => bottomsheet());
                        },
                        icon: Icon(
                          Icons.add_box_rounded,
                          color: Colors.pink,
                        ))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () async {
                  message = _controller.text.trim();
                  sendMessage(message!, 'text');
                  _controller.clear();
                },
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.pink,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bottomsheet() {
    return Container(
      height: 150,
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            chatsIcon(Icons.pin_drop, "Location", () async {
              _startUpdatingLocation();

              // ✅ Listen for location updates, but send message only ONCE
              location.onLocationChanged.listen((newlocation.LocationData currentLocation) async {
                if (currentLocation.latitude != null && currentLocation.longitude != null) {
                  _currentAddress = await _getAddressFromCoordinates(
                      currentLocation.latitude!, currentLocation.longitude!);

                  message =
                  "https://www.google.com/maps/search/?api=1&query=${currentLocation.latitude}%2C${currentLocation.longitude}. $_currentAddress";

                  if (!_sentLocation) { // ✅ Send message only ONCE
                    _sentLocation = true;
                    sendMessage(message!, 'link');
                  }

                  // ✅ Continue updating the location in Firebase without sending messages
                  DatabaseReference locationRef = FirebaseDatabase.instance.ref("users/sender/location");
                  await locationRef.set({
                    "latitude": currentLocation.latitude,
                    "longitude": currentLocation.longitude,
                    "accuracy": currentLocation.accuracy ?? 0.0,
                    "altitude": currentLocation.altitude ?? 0.0,
                    "heading": currentLocation.heading ?? 0.0,
                    "speed": currentLocation.speed ?? 0.0,
                    "address": _currentAddress,
                    "timestamp": ServerValue.timestamp,
                  });
                }
              });

              Navigator.pop(context); // ✅ Close the bottom sheet
            }),
            chatsIcon(Icons.camera_alt_rounded, "Camera", () async{
              await getImageFromCamera();
              Navigator.pop(context);
            }),
            chatsIcon(Icons.photo, "Photo", () async{
              await getImage();
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  chatsIcon(IconData icons, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.pink.shade400,
            child: Icon(icons),
          ),
          Text('$title')
        ],
      ),
    );
  }
}
