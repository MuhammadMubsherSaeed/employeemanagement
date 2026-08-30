import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_colors.dart';

enum AppAvatarSize {
  sm(32),
  md(40),
  lg(56);

  const AppAvatarSize(this.pixels);
  final double pixels;
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.image,
    this.name,
    this.size = 40,
  });

  final String? imageUrl;
  final String? assetPath;
  final ImageProvider? image;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initials = (name ?? '').initials;
    final Widget fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
        ),
      ),
    );

    if (image != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: image,
        onBackgroundImageError: (_, __) {},
        child: fallback,
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: AssetImage(assetPath!),
        onBackgroundImageError: (_, __) {},
        child: fallback,
      );
    }

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => fallback,
        errorWidget: (BuildContext context, String url, Object error) =>
            fallback,
      ),
    );
  }
}
