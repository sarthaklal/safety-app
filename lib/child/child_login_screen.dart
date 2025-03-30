import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safepath/child/bottom_page.dart';
import 'package:safepath/components/custom_textfield.dart';
import 'package:safepath/components/secondary_button.dart';
import 'package:safepath/child/register_child.dart';
import 'package:safepath/db/shared_preference.dart';
import 'package:safepath/child/bottom_screens/child_home_screen.dart';
import 'package:safepath/parent/parent_home_screen.dart';
import 'package:safepath/parent/parent_register_screen.dart';
import 'package:safepath/utils/constants.dart';

import '../components/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordShown = true;
  final _formKey = GlobalKey<FormState>();
  final _formData = Map<String, Object>();
  bool isLoading = false;
  Locale _locale = const Locale('en');

  void _changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  _onSubmit() async {
    _formKey.currentState!.save();
    try {
      setState(() {
        isLoading = true;
      });
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _formData['email'].toString(),
        password: _formData['password'].toString(),
      );
      if (userCredential.user != null) {
        setState(() {
          isLoading = false;
        });
        FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get()
            .then((onValue) {
          if (onValue['type'] == 'parent') {
            print(onValue['type']);
            SharedPref.saveUserType('parent');
            goTo(context, ParentHomeScreen());
          } else {
            SharedPref.saveUserType('child');
            goTo(context, BottomPage(onLanguageChanged: _changeLanguage));
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (e.code == 'user-not-found') {
        dialogueBox(context, 'No user found for that email.');
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        dialogueBox(context, 'Wrong password provided for that user.');
        print('Wrong password provided for that user.');
      }
    } catch (e) {
      print('Some other error');
      print(e.toString());
    }
    print(_formData['email']);
    print(_formData['password']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(children: [
          isLoading
              ? progressIndicator(context)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'User Login',
                          style: TextStyle(
                              fontSize: 35,
                              color: primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                        Image.asset(
                          'assets/logo.png',
                          height: 100,
                          width: 100,
                        ),
                      ],
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            hintText: 'Enter Email',
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            prefix: Icon(Icons.person),
                            onsave: (email) {
                              _formData['email'] = email ?? "";
                            },
                            validate: (email) {
                              if (email!.isEmpty ||
                                  email.length < 3 ||
                                  !email.contains("@")) {
                                return 'Enter correct email.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          CustomTextField(
                            hintText: 'Enter Password',
                            prefix: Icon(Icons.key),
                            onsave: (password) {
                              _formData['password'] = password ?? "";
                            },
                            validate: (password) {
                              if (password!.isEmpty || password.length < 7) {
                                return 'Enter correct password.';
                              }
                              return null;
                            },
                            isPassword: isPasswordShown,
                            suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isPasswordShown = !isPasswordShown;
                                  });
                                },
                                icon: isPasswordShown
                                    ? Icon(Icons.visibility_off)
                                    : Icon(Icons.visibility)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        PrimaryButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _onSubmit();
                              }
                            },
                            title: "Login"),
                        SecondaryButton(
                            onPressed: () {
                              //progressIndicator(context);
                              if (_formKey.currentState!.validate()) {
                                _onSubmit();
                              }
                            },
                            title: 'Forgot Password'),
                      ],
                    ),
                    Column(
                      children: [
                        SecondaryButton(
                            onPressed: () {
                              goTo(context, RegisterChild());
                            },
                            title: 'Register as Child'),
                        SecondaryButton(
                            onPressed: () {
                              goTo(context, RegisterParent());
                            },
                            title: 'Register as Parent'),
                      ],
                    ),
                  ],
                ),
        ]),
      )),
    );
  }
}
