import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/video_call/zego_config.dart';

/// A small wrapper around ZEGOCLOUD prebuilt video call UI.
///
/// It uses `callID` (per-appointment room) to connect two participants.
class VideoCallScreen extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;

  const VideoCallScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video consultation')),
      body: ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
        userID: userID,
        userName: userName,
        callID: callID,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
      ),
    );
  }
}
