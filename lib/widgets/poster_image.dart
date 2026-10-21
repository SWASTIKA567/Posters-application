import 'dart:io';
import 'package:flutter/material.dart';

class PosterImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const PosterImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    final trimmed = imagePath.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _loadingPlaceholder();
        },
        errorBuilder: (_, error, stackTrace) => _errorPlaceholder(),
      );
    } else if (trimmed.startsWith('assets/')) {
      content = Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, error, stackTrace) => _errorPlaceholder(),
      );
    } else if (trimmed.isNotEmpty) {
      try {
        final file = File(trimmed);
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, error, stackTrace) => _errorPlaceholder(),
        );
      } catch (_) {
        content = _errorPlaceholder();
      }
    } else {
      content = _errorPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F1F5),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black26,
          ),
        ),
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEBEBF0),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.black38,
          size: 26,
        ),
      ),
    );
  }
}
