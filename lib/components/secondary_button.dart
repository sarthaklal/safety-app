import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String title;
  final Function onPressed;
  SecondaryButton({required this.onPressed,required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextButton(onPressed: () {
        onPressed();
      }, child: Text(title,style: TextStyle(fontSize: 18),)),
    );
  }
}
