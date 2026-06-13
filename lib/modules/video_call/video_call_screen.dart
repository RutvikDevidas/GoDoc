import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../core/constants/app_colors.dart';
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
      return normalized.length <= 64 ? normalized : normalized.substring(0, 64);
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('Video consultation')),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF081B2B), Color(0xFF0B6E6E), Color(0xFFEAF7F4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33081B2B),
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE7F8F4), Color(0xFFD7EEF1)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Consultation room is ready',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'The video session UI has been designed, but ZEGOCLOUD credentials are still missing in this build. Add your App ID and App Sign in lib/core/video_call/zego_config.dart to activate live video.',
                        style: TextStyle(
                          height: 1.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ConsultationMetaCard(
                        resolvedCallID: resolvedCallID,
                        resolvedUserID: resolvedUserID,
                        userName: userName,
                      ),
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
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF081B2B),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF081B2B), Color(0xFF0C3448)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _CallHeaderButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Live consultation',
                                style: TextStyle(
                                  color: Color(0xFFBEE7E2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userName.trim().isEmpty
                                    ? resolvedUserID
                                    : userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: ZegoUIKitPrebuiltCall(
                        appID: ZegoConfig.appID,
                        appSign: ZegoConfig.appSign,
                        userID: resolvedUserID,
                        userName: userName.trim().isEmpty
                            ? resolvedUserID
                            : userName,
                        callID: resolvedCallID,
                        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultationMetaCard extends StatelessWidget {
  final String resolvedCallID;
  final String resolvedUserID;
  final String userName;

  const _ConsultationMetaCard({
    required this.resolvedCallID,
    required this.resolvedUserID,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Call ID', value: resolvedCallID),
          const SizedBox(height: 12),
          _InfoRow(label: 'User ID', value: resolvedUserID),
          const SizedBox(height: 12),
          _InfoRow(label: 'User name', value: userName),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.mutedText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }
}

class _CallHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CallHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
