import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum TopSnackbarVariant { info, success, warning, error }

class TopSnackbar {
  TopSnackbar._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    TopSnackbarVariant variant = TopSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (context) => _TopSnackbarOverlay(
        message: message,
        variant: variant,
        actionLabel: actionLabel,
        onAction: () {
          dismiss();
          onAction?.call();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopSnackbarOverlay extends StatefulWidget {
  final String message;
  final TopSnackbarVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopSnackbarOverlay({
    required this.message,
    required this.variant,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  State<_TopSnackbarOverlay> createState() => _TopSnackbarOverlayState();
}

class _TopSnackbarOverlayState extends State<_TopSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<Offset> _offsetAnimation =
      Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  Color get _accentColor {
    switch (widget.variant) {
      case TopSnackbarVariant.success:
        return AppColors.success;
      case TopSnackbarVariant.warning:
        return AppColors.warning;
      case TopSnackbarVariant.error:
        return AppColors.danger;
      case TopSnackbarVariant.info:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (widget.variant) {
      case TopSnackbarVariant.success:
        return Icons.check_circle_rounded;
      case TopSnackbarVariant.warning:
        return Icons.notifications_active_rounded;
      case TopSnackbarVariant.error:
        return Icons.error_rounded;
      case TopSnackbarVariant.info:
        return Icons.info_rounded;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SlideTransition(
              position: _offsetAnimation,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F172A),
                          _accentColor.withValues(alpha: 0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x330F172A),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null && widget.onAction != null)
                          TextButton(
                            onPressed: widget.onAction,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text(widget.actionLabel!),
                          ),
                        IconButton(
                          onPressed: TopSnackbar.dismiss,
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

