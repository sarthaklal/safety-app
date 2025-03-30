import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safepath/child/bottom_page.dart';
import 'package:safepath/db/shared_preference.dart';
import 'package:safepath/child/child_login_screen.dart';
import 'package:safepath/parent/parent_home_screen.dart';
import 'package:safepath/utils/background_services.dart';
import 'package:safepath/utils/constants.dart';
import 'package:safepath/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await Firebase.initializeApp();
  await SharedPref.init();


  // Retrieve saved locale
  String savedLanguageCode = await SharedPref.getLanguageCode() ?? 'en';
  runApp(MyApp(savedLocale: savedLanguageCode));
}

class MyApp extends StatefulWidget {
  final String savedLocale;

  const MyApp({super.key, required this.savedLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.savedLocale);
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
      SharedPref.saveLanguageCode(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePath',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        textTheme: GoogleFonts.firaSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: FutureBuilder(
        future: SharedPref.getUserType(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return progressIndicator(context);
          }
          if (snapshot.data == "") {
            return const LoginScreen();
          }
          if (snapshot.data == "child") {
            return BottomPage(onLanguageChanged: _changeLanguage);
          }
          if (snapshot.data == "parent") {
            return const ParentHomeScreen();
          }
          return progressIndicator(context);
        },
      ),
    );
  }
}
