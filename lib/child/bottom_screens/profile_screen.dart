import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safepath/child/child_login_screen.dart';
import 'package:safepath/components/custom_textfield.dart';
import 'package:safepath/components/primary_button.dart';
import 'package:safepath/components/settings_page.dart';
import 'package:safepath/utils/constants.dart';
import 'package:uuid/uuid.dart';

import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {

  final Function(String) onLanguageChanged;

  const ProfileScreen({super.key, required this.onLanguageChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController nameC = TextEditingController();
  TextEditingController numC = TextEditingController();
  final key = GlobalKey<FormState>();
  String? id;
  String? profilePic;
  String? downloadUrl;
  bool isSaving = false;

  getData() async {
    await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((value) {
      setState(() {
        nameC.text = value.docs.first['name'];
        numC.text = value.docs.first['phone'];
        id = value.docs.first.id;
        profilePic = value.docs.first['profilePic'];
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    var localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          Center(
            child: IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SettingsPage(onLanguageChanged: widget.onLanguageChanged,)));
                },
                icon: Icon(Icons.settings)),
          )
        ],
      ),
      body: isSaving == true
          ? Center(
              child: CircularProgressIndicator(
              backgroundColor: Colors.pink,
            ))
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizations!.translate("Update your profile"),
                        style: TextStyle(fontSize: 25),
                      ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () async {
                          final XFile? pickImage = await ImagePicker()
                              .pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 50);
                          if (pickImage != null) {
                            setState(() {
                              profilePic = pickImage.path;
                            });
                          }
                        },
                        child: Container(
                          child: profilePic == null
                              ? CircleAvatar(
                                  child: Center(
                                      child: Image.asset(
                                    'assets/add_pic.png',
                                    height: 35,
                                  )),
                                  radius: 40,
                                )
                              : profilePic!.contains('http')
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          NetworkImage(profilePic!),
                                    )
                                  : CircleAvatar(
                                      backgroundImage:
                                          FileImage(File(profilePic!)),
                                      radius: 40,
                                    ),
                        ),
                      ),
                      SizedBox(height: 30),
                      CustomTextField(
                        controller: nameC,
                        hintText: nameC.text,
                        validate: (v) {
                          if (v!.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        controller: numC,
                        hintText: numC.text,
                        validate: (v) {
                          if (v!.isEmpty) {
                            return 'Please enter your number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      PrimaryButton(
                          title: localizations!.translate("Update"),
                          onPressed: () async {
                            if (key.currentState!.validate()) {
                              SystemChannels.textInput
                                  .invokeMethod('TextInput.hide');
                              profilePic == null
                                  ? Fluttertoast.showToast(
                                      msg:
                                          'Please Update profile picture')
                                  : update();
                            }
                          }),
                      SizedBox(
                        height: 10,
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          } on FirebaseAuthException catch (e) {
                          }
                        },
                        child: Text(
                          localizations!.translate("Sign Out"),
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<String?> uploadImg(String filePath) async {
    try {
      final fileName = Uuid().v4();
      final Reference fbStorage =
          FirebaseStorage.instance.ref('profile').child(fileName);
      final UploadTask uploadTask = fbStorage.putFile(File(filePath));
      await uploadTask.then((p0) async {
        downloadUrl = await fbStorage.getDownloadURL();
      });
      return downloadUrl;
    } catch (e) {
      print(e);
    }
  }

  update() async {
    setState(() {
      isSaving = true;
    });
    uploadImg(profilePic!).then((value) {
      Map<String, dynamic> data = {
        'name': nameC.text,
        'profilePic': downloadUrl,
        'phone':numC.text,
      };
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(data);
      setState(() {
        isSaving = false;
      });
    });
  }
}
