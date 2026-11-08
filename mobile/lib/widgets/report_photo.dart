import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Foto saluran: file lokal (laporan sendiri), URL server, atau pengganti
/// netral kalau belum ada foto (mis. data contoh).
class ReportPhoto extends StatelessWidget {
  const ReportPhoto({
    super.key,
    this.file,
    this.url,
    this.width,
    this.height,
    this.radius = Radii.md,
    required this.semanticLabel,
  });

  final File? file;
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(width: width, height: height);
    final Widget image;
    if (file != null) {
      image = Image.file(
        file!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else if (url != null && url!.isNotEmpty) {
      image = Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    } else {
      image = Semantics(label: semanticLabel, image: true, child: placeholder);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final besar = (height ?? 0) >= 120;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: scheme.onSurfaceVariant,
            size: besar ? 32 : 24,
          ),
          if (besar) ...[
            const SizedBox(height: Space.sm),
            Text(
              'Foto belum tersedia',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
