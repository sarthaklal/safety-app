import 'package:direct_call_plus/direct_call_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class FireEmergency extends StatelessWidget {
  const FireEmergency({super.key});
  _callNumber(String number) async{
    await DirectCallPlus.makeCall(number);
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 5),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _callNumber('101'),
          child: Container(
            height: 180,
            width: MediaQuery.of(context).size.width*0.7,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                    colors: [
                      Color(0XFFFD8080),
                      Color(0XFFFB8580),
                      Color(0XFFFBD079),
                    ])
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: Image.asset('assets/flame.png'),
                    backgroundColor: Colors.white.withOpacity(0.5),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations!.translate("Fire Emergency"),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width*0.06
                          ),
                        ),
                        Text(
                          "Call 101",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width*0.045
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '1-0-1',
                              style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(context).size.width*0.05
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
