import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/app_image_cache_manager.dart';

/// Reusable production-grade cached image component for ElderCare.
/// Utilizes bounded disk and memory caching via [AppImageCacheManager],
/// renders a themed shimmer skeleton while loading, and falls back gracefully.
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final String? cacheKey;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 300,
    this.memCacheHeight = 300,
    this.cacheKey,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = imageUrl?.trim() ?? '';
    final isNetwork = effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://');

    Widget imageContent;

    if (!isNetwork) {
      imageContent = _buildErrorWidget(context);
    } else {
      final key = cacheKey ?? AppImageCacheManager.getStableCacheKey(effectiveUrl);

      imageContent = CachedNetworkImage(
        imageUrl: effectiveUrl,
        cacheKey: key,
        cacheManager: AppImageCacheManager.instance,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (context, url) => placeholder ?? _buildShimmer(context),
        errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Image.asset(
            'assets/images/def_png.png',
            fit: fit,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.person, color: Colors.grey, size: 28),
            ),
          ),
        );
  }
}

/// Circular avatar widget with cached network image support, local file preview,
/// and smooth shimmer loading.
class AppCachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final double radius;
  final Color? backgroundColor;
  final IconData iconFallback;
  final Color? iconColor;
  final String? heroTag;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const AppCachedAvatar({
    super.key,
    this.imageUrl,
    this.localFile,
    this.radius = 24,
    this.backgroundColor,
    this.iconFallback = Icons.person,
    this.iconColor,
    this.heroTag,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;

    Widget avatarContent;

    if (localFile != null && localFile!.existsSync()) {
      // Local preview takes precedence (e.g. during profile photo editing)
      avatarContent = Image.file(
        localFile!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty && (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'))) {
      avatarContent = AppCachedImage(
        imageUrl: imageUrl,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        memCacheWidth: (diameter * 2).toInt(),
        memCacheHeight: (diameter * 2).toInt(),
        placeholder: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? Colors.grey.shade200,
            ),
          ),
        ),
        errorWidget: _buildFallbackIcon(),
      );
    } else {
      avatarContent = _buildFallbackIcon();
    }

    Widget circleContainer = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey.shade100,
        border: border,
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      circleContainer = Hero(
        tag: heroTag!,
        child: circleContainer,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: circleContainer,
      );
    }

    return circleContainer;
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        iconFallback,
        size: radius,
        color: iconColor ?? Colors.grey.shade500,
      ),
    );
  }
}
