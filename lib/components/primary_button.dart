import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safepath/utils/constants.dart';

class PrimaryButton extends StatelessWidget {

  final String title;
  final Function onPressed;
  bool loading;
  PrimaryButton({this.loading=false,required this.onPressed,required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
          onPressed: () {
            onPressed();
          },
          child: Text(title, style: TextStyle(fontSize: 18, color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
      ),
    );
  }
}
