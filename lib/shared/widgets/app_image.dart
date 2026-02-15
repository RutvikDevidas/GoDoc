import 'dart:io';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String pathOrUrl;
  final double width;
  final double height;
  final double radius;

  const AppImage({
    super.key,
    required this.pathOrUrl,
    required this.width,
    required this.height,
    this.radius = 14,
  });

  bool get _isNetwork => pathOrUrl.startsWith("http");

  @override
  Widget build(BuildContext context) {
    final provider = _isNetwork
        ? NetworkImage(pathOrUrl)
        : FileImage(File(pathOrUrl)) as ImageProvider;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image(
        image: provider,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
