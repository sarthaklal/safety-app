import 'package:background_sms/background_sms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safepath/components/primary_button.dart';
import 'package:safepath/db/db_services.dart';
import 'package:safepath/model/contacts_model.dart';

import '../../../l10n/app_localizations.dart';

class SafeHome extends StatefulWidget {
  const SafeHome({super.key});

  @override
  State<SafeHome> createState() => _SafeHomeState();
}

class _SafeHomeState extends State<SafeHome> {
  Position? _currentPosition;
  String? _currentAddress;
  LocationPermission? permission;

  _getPermission() async => await [Permission.sms].request();

  _isPermissionGranted() async => await Permission.sms.isGranted;

  _sendSms(String phoneNo, String message, {int? sim}) async {
    await BackgroundSms.sendMessage(
            phoneNumber: phoneNo, message: message, simSlot: sim)
        .then((SmsStatus status) {
      if (status == SmsStatus.sent) {
        Fluttertoast.showToast(msg: 'Sent');
      }else if (status == SmsStatus.failed) { // Adjust for failed status
        Fluttertoast.showToast(msg: 'Message Failed to Send');
      } else {
        Fluttertoast.showToast(msg: 'Unknown status: $status');
      }
    });
  }

  _getCurrentLocation() async {
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

  @override
  void initState() {
    super.initState();
    _getPermission();
    _getCurrentLocation();
  }

  showModelSafeHome(BuildContext context, var localizations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows dynamic height changes
      builder: (context) {
        return StatefulBuilder( // ✅ Ensures UI updates when setState is called
          builder: (context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height / 1.4,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations!.translate("Send Your Current Location"),
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    if (_currentAddress != null)
                      Text(_currentAddress!),
                    PrimaryButton(
                      title: localizations!.translate("Get Location"),
                      onPressed: () async {
                        await _getCurrentLocation();
                        setStateModal(() {}); // ✅ Refresh UI inside modal
                      },
                    ),
                    SizedBox(height: 10),
                    PrimaryButton(
                      title: localizations!.translate("Send Alert"),
                      onPressed: () async {
                        List<TContact> contactList =
                        await DatabaseHelper().getContactList();
                        String messageBody =
                            "https://www.google.com/maps/search/?api=1&query=${_currentPosition?.latitude}%2C${_currentPosition?.longitude}. $_currentAddress";
                        if (await _isPermissionGranted()) {
                          for (var contact in contactList) {
                            _sendSms("${contact.number}",
                                "Please help me at $messageBody", sim: 1);
                          }
                        } else {
                          Fluttertoast.showToast(msg: 'SMS permission required');
                        }
                      },
                    ),
                  ],
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return InkWell(
      onTap: () => showModelSafeHome(context, localizations),
      child: Card(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 180,
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                  child: Column(
                children: [
                  ListTile(
                    title: Text(localizations!.translate("Send Location")),
                    subtitle: Text(localizations!.translate("Share Location")),
                  )
                ],
              )),
              ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/route.jpg'))
            ],
          ),
        ),
      ),
    );
  }
}
