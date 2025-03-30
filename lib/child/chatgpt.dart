import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:safepath/utils/constants.dart';

class AiChat extends StatefulWidget {
  const AiChat({super.key});
  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  TextEditingController _userInput = TextEditingController();
  static const apiKey = GEMINI_API_KEY;
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final List<Message> _messages = [];
  final CollectionReference chatsCollection =
      FirebaseFirestore.instance.collection('chats');
  final ScrollController _scrollController = ScrollController();

  Future<void> sendMessage() async {
    final message = _userInput.text;
    final timestamp = DateTime.now();

    // Add user message to the UI
    setState(() {
      _messages.add(Message(isUser: true, message: message, date: timestamp));
    });

    _scrollToBottom();

    // Save user message to Firestore
    await chatsCollection.add({
      'isUser': true,
      'message': message,
      'date': timestamp,
    });

    final content = [Content.text(message)];
    final response = await model.generateContent(content);
    final aiMessage = response.text ?? "";

    setState(() {
      _messages.add(
          Message(isUser: false, message: aiMessage, date: DateTime.now()));
    });

    _scrollToBottom();

    await chatsCollection.add({
      'isUser': false,
      'message': aiMessage,
      'date': DateTime.now(),
    });
  }

  Future<void> loadMessages() async {
    final querySnapshot =
        await chatsCollection.orderBy('date', descending: false).get();
    setState(() {
      _messages.addAll(querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Message(
          isUser: data['isUser'] ?? false,
          message: data['message'] ?? "",
          date: (data['date'] as Timestamp).toDate(),
        );
      }).toList());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat wit AI"),
          backgroundColor: primaryColor,
        ),
        body: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Messages(
                            isUser: message.isUser,
                            message: message.message,
                            date: DateFormat('HH:mm').format(message.date));
                      })),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 15,
                      child: TextFormField(
                        style: TextStyle(color: Colors.black),
                        controller: _userInput,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            label: Text('Enter Your Message')),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                        padding: EdgeInsets.all(12),
                        iconSize: 30,
                        style: ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.black),
                            foregroundColor:
                                WidgetStatePropertyAll(Colors.white),
                            shape: WidgetStatePropertyAll(CircleBorder())),
                        onPressed: () {
                          sendMessage();
                        },
                        icon: Icon(Icons.send))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  Message({required this.isUser, required this.message, required this.date});
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  const Messages(
      {super.key,
      required this.isUser,
      required this.message,
      required this.date});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 15)
          .copyWith(left: isUser ? 100 : 10, right: isUser ? 10 : 100),
      decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade400,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: isUser ? Radius.circular(10) : Radius.zero,
              topRight: Radius.circular(10),
              bottomRight: isUser ? Radius.zero : Radius.circular(10))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
                fontSize: 16, color: isUser ? Colors.white : Colors.black),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 10,
              color: isUser ? Colors.white : Colors.black,
            ),
          )
        ],
      ),
    );
  }
}
