import 'dart:io';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.size,
  });

  final String source;
  final BoxFit fit;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.eco_outlined,
      size: size == null ? 28 : size! * .42,
      color: const Color(0xFF5CA399),
    );
    if (source.isEmpty) return fallback;

    final file = File(source);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      source,
      fit: fit,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
