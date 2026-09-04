import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/theme/app_colors.dart';
import 'package:flutter_base/core/theme/app_dimensions.dart';

enum AppAvatarSize {
  sm(AppDimensions.avatarSm),
  md(AppDimensions.avatarMd),
  lg(AppDimensions.avatarLg),
  xl(AppDimensions.avatarXl);

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
    this.size = AppDimensions.avatarMd,
  });

  final String? imageUrl;
  final String? assetPath;
  final ImageProvider? image;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initials = (name ?? '').initials;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.infoOf(Theme.of(context).brightness),
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
        ),
      ),
    );

    Widget framed(Widget child) {
      return SizedBox(
        width: size,
        height: size,
        child: child,
      );
    }

    if (image != null) {
      return framed(
        CircleAvatar(
          radius: size / 2,
          backgroundImage: image,
          onBackgroundImageError: (_, __) {},
          child: fallback,
        ),
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return framed(
        CircleAvatar(
          radius: size / 2,
          backgroundImage: AssetImage(assetPath!),
          onBackgroundImageError: (_, __) {},
          child: fallback,
        ),
      );
    }

    if (imageUrl == null || imageUrl!.isEmpty) {
      return framed(fallback);
    }

    return framed(
      ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (BuildContext context, String url) => fallback,
          errorWidget: (BuildContext context, String url, Object error) =>
              fallback,
        ),
      ),
    );
  }
}
