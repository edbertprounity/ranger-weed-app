import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/local/photo_store.dart';
import '../data/models/site.dart';

class SitePhoto extends StatelessWidget {
  const SitePhoto({super.key, required this.site, this.height = 180});

  final Site site;
  final double height;

  @override
  Widget build(BuildContext context) {
    final path = site.photoPath;
    final url = site.photoUrl;
    Widget child;
    final file = path == null ? null : File(resolvePhotoPath(path));
    if (file != null && file.existsSync()) {
      child = Image.file(file, fit: BoxFit.cover, width: double.infinity);
    } else if (url != null && url.isNotEmpty) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _PhotoFallback(),
      );
    } else {
      child = const _PhotoFallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: SizedBox(height: height, width: double.infinity, child: child),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: panel,
      child: Center(
        child: Icon(Icons.crop_original, size: 28, color: muted),
      ),
    );
  }
}
