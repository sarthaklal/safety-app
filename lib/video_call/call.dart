import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:safepath/utils/settings.dart';

class CallPage extends StatefulWidget {
  final String? channelName;
  final ClientRoleType? roleType;

  const CallPage({super.key, this.channelName, this.roleType});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[]; // List to store remote user UIDs
  final _infoStrings = <String>[]; // Info strings to display logs
  bool muted = false; // Mute state for the local user
  bool viewPanel = false; // State for showing/hiding info panel
  late RtcEngine _engine; // The Agora RtcEngine instance

  @override
  void initState() {
    super.initState();
    initialize(); // Initialize the Agora engine
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.release(); // Proper cleanup
    super.dispose();
  }

  Future<void> initialize() async {
    if (widget.channelName == null || widget.roleType == null) {
      setState(() {
        _infoStrings.add("Channel Name or Role Type is null");
      });
      return;
    }

    // Initialize Agora Engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(appId: appId),
    );

    // Set event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _infoStrings.add("Successfully joined the channel!");
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _infoStrings.add("User $remoteUid joined");
            _users.add(remoteUid);
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _infoStrings.add("User $remoteUid left");
            _users.remove(remoteUid);
          });
        },
        onLeaveChannel: (connection, stats) {
          setState(() {
            _infoStrings.add("Left channel");
            _users.clear();
          });
        },
      ),
    );

    // Enable video
    await _engine.enableVideo();

    // Join the channel
    await _engine.joinChannel(
      token: token, // Replace with your token
      channelId: widget.channelName!,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: widget.roleType!,
      ),
    );
  }

  Widget _buildVideoViews() {
    final List<Widget> views = [];

    // Local user view
    views.add(
      AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: 0), // Local user's video
        ),
      ),
    );

    // Remote users' views
    for (int uid in _users) {
      views.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid), // Remote user's video
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: views.map((view) => Expanded(child: view)).toList(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(muted ? Icons.mic_off : Icons.mic, color: Colors.white),
            onPressed: _onToggleMute,
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera, color: Colors.white),
            onPressed: _onSwitchCamera,
          ),
        ],
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: ListView.builder(
        reverse: true,
        itemCount: _infoStrings.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _infoStrings[index],
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Call"),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildVideoViews(),
          _buildInfoPanel(),
          _buildToolbar(),
        ],
      ),
    );
  }
}
