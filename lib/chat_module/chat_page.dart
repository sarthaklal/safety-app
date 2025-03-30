import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:direct_call_plus/direct_call_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:safepath/chat_module/message_textfield.dart';
import 'package:safepath/chat_module/single_message.dart';
import 'package:safepath/utils/constants.dart';
import 'package:safepath/video_call/index.dart';

import '../child/child_login_screen.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String friendId;
  final String friendName;

  const ChatPage(
      {super.key,
      required this.currentUserId,
      required this.friendId,
      required this.friendName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? type;
  String? myName;
  String? friendPhone;
  final ScrollController _scrollController = ScrollController();

  getStatus() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get()
        .then((value) {
      setState(() {
        type = value.data()!['type'];
        myName = value.data()!['name'];
      });
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendId)
        .get()
        .then((value) {
      setState(() {
        friendPhone = value.data()!['phone'];
      });
    });
  }

  void scrollToBottom() {
    // Method to automatically scroll to the bottom.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    getStatus();
    super.initState();
  }

  _callNumber() async {
    if (friendPhone != null && friendPhone!.isNotEmpty) {
      await DirectCallPlus.makeCall(friendPhone!);
    } else {
      Fluttertoast.showToast(msg: 'Phone number not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor.withOpacity(0.85),
        title: Text(widget.friendName),
        actions: [
          Center(
            child: IconButton(
              icon: Icon(
                Icons.call,
                size: 30,
              ),
              onPressed: () {
                _callNumber();
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentUserId)
                    .collection('messages')
                    .doc(widget.friendId)
                    .collection('chats')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.docs.length < 1) {
                      return Center(
                        child: Text(
                          type == 'parent'
                              ? 'Talk with Child'
                              : 'Talk with Parent',
                          style: TextStyle(fontSize: 30),
                        ),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      scrollToBottom();
                    });
                    return Container(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (BuildContext context, int index) {
                          bool isMe = snapshot.data!.docs[index]['senderId'] ==
                              widget.currentUserId;
                          final data = snapshot.data!.docs[index];
                          return Dismissible(
                            key: UniqueKey(),
                            onDismissed: (dismissed) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.currentUserId)
                                  .collection('messages')
                                  .doc(widget.friendId)
                                  .collection('chats')
                                  .doc(data.id)
                                  .delete();
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.friendId)
                                  .collection('messages')
                                  .doc(widget.currentUserId)
                                  .collection('chats')
                                  .doc(data.id)
                                  .delete()
                                  .then((onValue) => Fluttertoast.showToast(
                                      msg: 'Successfully Deleted'));
                            },
                            child: SingleMessage(
                              message: data['message'],
                              date: data['date'],
                              isMe: isMe,
                              friendName: widget.friendName,
                              myName: myName,
                              type: data['type'],
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return progressIndicator(context);
                }),
          ),
          MessageTextfield(
            currentId: widget.currentUserId,
            friendId: widget.friendId,
          ),
        ],
      ),
    );
  }
}
