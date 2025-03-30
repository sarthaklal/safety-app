import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safepath/child/child_login_screen.dart';
import 'package:safepath/model/user_model.dart';
import 'package:safepath/utils/constants.dart';
import '../components/custom_textfield.dart';
import '../components/primary_button.dart';
import '../components/secondary_button.dart';

class RegisterChild extends StatefulWidget {
  @override
  State<RegisterChild> createState() => _RegisterChildState();
}

class _RegisterChildState extends State<RegisterChild> {
  bool isPasswordShown = true;
  bool isrPasswordShown = true;

  final _formKey = GlobalKey<FormState>();

  final _formData = Map<String, Object>();
  bool isLoading = false;

  _onSubmit() async {
    _formKey.currentState!.save();
    if (_formData['password'] != _formData['rpassword']) {
      dialogueBox(context, 'Both passwords should be same');
    } else {
      progressIndicator(context);
      try {
        setState(() {
          isLoading = true;
        });
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _formData['cemail'].toString(),
          password: _formData['password'].toString(),
        );
        if (credential.user != null) {
          final v = credential.user!.uid;
          DocumentReference<Map<String, dynamic>> db =
              FirebaseFirestore.instance.collection('users').doc(v);
          final user = UserModel(
            name: _formData['name'].toString(),
            phone: _formData['phone'].toString(),
            childEmail: _formData['cemail'].toString(),
            parentEmail: _formData['gemail'].toString(),
            id: v,
            type: 'child',
          );
          final jsonData = user.toJson();
          await db.set(jsonData).whenComplete(() {
            goTo(context, LoginScreen());
            setState(() {
              isLoading = false;
            });
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          isLoading = false;
        });
        if (e.code == 'weak-password') {
          dialogueBox(context, 'The password provided is too weak.');
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          dialogueBox(context, 'The account already exists for that email.');
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
        setState(() {
          isLoading = false;
        });
        dialogueBox(context, e.toString());
      }
    }
    print(_formData['cemail']);
    print(_formData['password']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            children: [
              isLoading
                  ? progressIndicator(context)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Register Child",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Image.asset(
                                  'assets/logo.png',
                                  height: 100,
                                  width: 100,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.75,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  CustomTextField(
                                    hintText: 'Enter Name',
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.name,
                                    prefix: Icon(Icons.person),
                                    onsave: (name) {
                                      _formData['name'] = name ?? "";
                                    },
                                    validate: (email) {
                                      if (email!.isEmpty || email.length < 3) {
                                        return 'Enter correct name';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'Enter Phone',
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.phone,
                                    prefix: Icon(Icons.phone),
                                    onsave: (phone) {
                                      _formData['phone'] = phone ?? "";
                                    },
                                    validate: (phone) {
                                      if (phone!.isEmpty || phone.length < 10) {
                                        return 'Enter correct phone';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'Enter Email',
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress,
                                    prefix: Icon(Icons.person),
                                    onsave: (email) {
                                      _formData['cemail'] = email ?? "";
                                    },
                                    validate: (email) {
                                      if (email!.isEmpty ||
                                          email.length < 3 ||
                                          !email.contains("@")) {
                                        return 'Enter correct email';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'Enter Guardian Email',
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress,
                                    prefix: Icon(Icons.person),
                                    onsave: (gemail) {
                                      _formData['gemail'] = gemail ?? "";
                                    },
                                    validate: (gemail) {
                                      if (gemail!.isEmpty ||
                                          gemail.length < 3 ||
                                          !gemail.contains("@")) {
                                        return 'Enter correct email';
                                      }
                                      return null;
                                    },
                                  ),
                                  CustomTextField(
                                    hintText: 'Enter Password',
                                    isPassword: isPasswordShown,
                                    prefix: Icon(Icons.vpn_key_rounded),
                                    validate: (password) {
                                      if (password!.isEmpty ||
                                          password.length < 7) {
                                        return 'Enter correct password';
                                      }
                                      return null;
                                    },
                                    onsave: (password) {
                                      _formData['password'] = password ?? "";
                                    },
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
                                  CustomTextField(
                                    hintText: 'Re-enter Password',
                                    isPassword: isrPasswordShown,
                                    prefix: Icon(Icons.vpn_key_rounded),
                                    validate: (password) {
                                      if (password!.isEmpty ||
                                          password.length < 7) {
                                        return 'Enter correct password';
                                      }
                                      return null;
                                    },
                                    onsave: (password) {
                                      _formData['rpassword'] = password ?? "";
                                    },
                                    suffix: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            isrPasswordShown = !isrPasswordShown;
                                          });
                                        },
                                        icon: isrPasswordShown
                                            ? Icon(Icons.visibility_off)
                                            : Icon(Icons.visibility)),
                                  ),
                                  PrimaryButton(
                                      title: 'REGISTER',
                                      onPressed: () {
                                        // progressIndicator(context);
                                        if (_formKey.currentState!.validate()) {
                                          _onSubmit();
                                        }
                                      }),
                                ],
                              ),
                            ),
                          ),
                          SecondaryButton(
                              title: 'Login with your account',
                              onPressed: () {
                                goTo(context, LoginScreen());
                              }),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
