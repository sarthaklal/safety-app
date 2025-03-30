import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../chat_module/chat_page.dart';
import '../child/child_login_screen.dart';
import '../utils/constants.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
                child: Container()
            ),
            ListTile(
              title: TextButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      goTo(context, LoginScreen());
                    }on FirebaseAuthException catch (e) {
                      dialogueBox(context, e.toString());
                    }
                  },
                  child: Text('Sign Out')),
            )
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Select Child'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'child')
            .where('parentEmail',
            isEqualTo: FirebaseAuth.instance.currentUser!.email)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Center(child: progressIndicator(context));
          }
          return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (BuildContext context, int index) {
                final d = snapshot.data!.docs[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: primaryColor.withOpacity(0.1),
                    child: ListTile(
                      onTap: () {
                        goTo(
                            context,
                            ChatPage(
                                currentUserId:
                                FirebaseAuth.instance.currentUser!.uid,
                                friendId: d.id,
                                friendName: d['name']));
                      },
                      title: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d['name']),
                      ),
                    ),
                  ),
                );
              });
        },
      ),
    );
  }
}
