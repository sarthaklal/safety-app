import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safepath/chat_module/chat_page.dart';
import 'package:safepath/child/chatgpt.dart';
import 'package:safepath/utils/constants.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Select Guardian'),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AiChat()));
          }, icon: Icon(Icons.computer_rounded))
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('type', isEqualTo: 'parent')
            .where('childEmail',
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
