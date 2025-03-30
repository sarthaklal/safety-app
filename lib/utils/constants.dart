import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Color primaryColor= Color(0xfffc3b77);

const GEMINI_API_KEY = "YOUR_API_KEY";

const geocodingApi = 'YOUR_API_KEY';


void goTo(BuildContext context, Widget nextScreen)
{
  Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen));
}


Widget progressIndicator(BuildContext context)
{
  return Center(child: CircularProgressIndicator());
}


dialogueBox(BuildContext context, String text)
{
  showDialog(context: context, builder: (context) => AlertDialog(title: Text(text)));
}
