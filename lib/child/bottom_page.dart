import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safepath/child/bottom_screens/add_contacts.dart';
import 'package:safepath/child/bottom_screens/chat_screen.dart';
import 'package:safepath/child/bottom_screens/child_home_screen.dart';
import 'package:safepath/child/bottom_screens/contact_screen.dart';
import 'package:safepath/child/bottom_screens/profile_screen.dart';
import 'package:safepath/child/bottom_screens/review_screen.dart';

import '../l10n/app_localizations.dart';

class BottomPage extends StatefulWidget {
  final Function(String) onLanguageChanged;

  const BottomPage({super.key, required this.onLanguageChanged});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  int currentIndex = 0;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(),
      AddContacts(),
      ChatScreen(),
      ReviewScreen(),
      ProfileScreen(onLanguageChanged: widget.onLanguageChanged),
    ];
  }

  onTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onTapped,
        items: [
          BottomNavigationBarItem(label: localizations!.translate("Home"), icon: Icon(Icons.home)),
          BottomNavigationBarItem(label: localizations!.translate("Contacts"), icon: Icon(Icons.contacts)),
          BottomNavigationBarItem(label: localizations!.translate("Chat"), icon: Icon(Icons.chat)),
          BottomNavigationBarItem(label: localizations!.translate("Review"), icon: Icon(Icons.reviews)),
          BottomNavigationBarItem(label: localizations!.translate("Profile"), icon: Icon(Icons.person)),
        ],
      ),
    );
  }
}
