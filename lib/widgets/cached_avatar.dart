// lib/widgets/cached_avatar.dart
//
// Thin wrappers around CachedNetworkImage for the two common patterns:
//   1. CachedAvatar — CircleAvatar with disk-cached network background
//   2. CachedImage  — rectangular image with placeholder + error fallback

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// A [CircleAvatar] whose background image is disk-cached.
///
/// Shows [fallbackIcon] (or [fallbackChild]) while loading and on error.
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackIcon,
    this.fallbackChild,
    this.backgroundColor,
  });

  final String? imageUrl;
  final double radius;
  final IconData? fallbackIcon;
  final Widget? fallbackChild;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.primaryColor.withValues(alpha: 0.15);
    final fallback = fallbackChild ??
        Icon(fallbackIcon ?? Icons.person,
            size: radius, color: AppTheme.textSecondary);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: bg, child: fallback);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (_, provider) => CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: provider,
      ),
      placeholder: (_, __) =>
          CircleAvatar(radius: radius, backgroundColor: bg, child: fallback),
      errorWidget: (_, __, ___) =>
          CircleAvatar(radius: radius, backgroundColor: bg, child: fallback),
    );
  }
}

/// A rectangular [CachedNetworkImage] with a shimmer placeholder and
/// broken-image fallback.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: AppTheme.backgroundGray,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: AppTheme.backgroundGray,
        child: const Icon(Icons.broken_image_outlined,
            color: AppTheme.textSecondary),
      ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
