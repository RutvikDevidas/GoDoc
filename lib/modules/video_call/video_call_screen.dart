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

  String _normalizedIdentifier(String value, {required String fallbackPrefix}) {
    final trimmed = value.trim();
    final normalized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (normalized.isNotEmpty) {
      return normalized.length <= 64
          ? normalized
          : normalized.substring(0, 64);
    }

    final checksum = trimmed.codeUnits.fold<int>(
      0,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    return '${fallbackPrefix}_$checksum';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCallID = _normalizedIdentifier(
      callID,
      fallbackPrefix: 'call',
    );
    final resolvedUserID = _normalizedIdentifier(
      userID,
      fallbackPrefix: 'user',
    );

    if (!ZegoConfig.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video consultation')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.videocam_outlined,
                      size: 30,
                      color: Color(0xFF0E7490),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Video call screen is ready',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ZEGOCLOUD is not configured yet, so the live camera view cannot start in this build. Add your Zego App ID and App Sign in lib/core/video_call/zego_config.dart to enable real calls.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(label: 'Call ID', value: resolvedCallID),
                  _InfoRow(label: 'User ID', value: resolvedUserID),
                  _InfoRow(label: 'User name', value: userName),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to appointments'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Video consultation')),
      body: ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
        userID: resolvedUserID,
        userName: userName.trim().isEmpty ? resolvedUserID : userName,
        callID: resolvedCallID,
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
