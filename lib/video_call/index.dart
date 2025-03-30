import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safepath/video_call/call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType? _roleType = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Text('Video Call'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                height: 40,
              ),
              Image.network('https://tinyurl.com/2p889y4k'),
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: _channelController,
                decoration: InputDecoration(
                    errorText:
                        _validateError ? 'Channel name is mandatory' : null,
                    border:
                        UnderlineInputBorder(borderSide: BorderSide(width: 1)),
                    hintText: 'Channel Name'),
              ),
              RadioListTile(
                title: Text('Broadcaster'),
                onChanged: (ClientRoleType? value) {
                  setState(() {
                    _roleType = value;
                  });
                },
                value: ClientRoleType.clientRoleBroadcaster,
                groupValue: _roleType,
              ),
              RadioListTile(
                title: Text('Audience'),
                onChanged: (ClientRoleType? value) {
                  setState(() {
                    _roleType = value;
                  });
                },
                value: ClientRoleType.clientRoleAudience,
                groupValue: _roleType,
              ),
              ElevatedButton(onPressed: onJoin, child: Text('Join'))
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> onJoin() async {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallPage(
                  channelName: _channelController.text,
                  roleType: _roleType
              ),
          ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
  }
}
