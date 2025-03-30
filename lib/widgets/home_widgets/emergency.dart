import 'package:flutter/cupertino.dart';
import 'package:safepath/widgets/home_widgets/emergencies/women_emergency.dart';
import 'emergencies/ambulance_emergency.dart';
import 'emergencies/fire_emergency.dart';
import 'emergencies/police_emergency.dart';

class Emergency extends StatelessWidget {
  const Emergency({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          WomenEmergency(),
          PoliceEmergency(),
          AmbulanceEmergency(),
          FireEmergency(),

        ],
      ),
    );
  }
}
