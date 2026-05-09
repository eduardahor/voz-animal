import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/foto_service.dart';

/// Widget que exibe a foto da denúncia, lidando com placeholder vs arquivo real.
class FotoDenuncia extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const FotoDenuncia({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(8);

    Widget child;
    if (path == null) {
      child = Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported,
            color: Colors.grey.shade600, size: 32),
      );
    } else if (FotoService.isPlaceholder(path) || kIsWeb) {
      child = Image.asset(
        FotoService.placeholderAsset,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      child = Image.file(
        File(path!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(
          FotoService.placeholderAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    return ClipRRect(borderRadius: br, child: child);
  }
}
