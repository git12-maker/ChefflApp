import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/colors.dart';
import 'image_progress_loader.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    required this.title,
    this.imageUrl,
    this.isLoading = false,
    this.height = 220,
  });

  final String title;
  final String? imageUrl;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Show progress loader for image generation
      return ImageProgressLoader(
        height: height,
        message: 'Creating beautiful image...',
        estimatedTime: 12,
      );
    }

    if (imageUrl == null) {
      return _fallback(context);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          final cacheWidth = (height * devicePixelRatio).round();
          
          return CachedNetworkImage(
            imageUrl: imageUrl!,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 100),
            placeholder: (_, __) => _shimmerPlaceholder(context),
            errorWidget: (_, __, ___) => _fallback(context),
            // HD quality - cache full resolution images for sharp display
            // Use higher cache limits for HD images (1024x1024 from Replicate)
            memCacheWidth: cacheWidth > 2048 ? 2048 : cacheWidth,
            maxWidthDiskCache: 2048, // HD cache
            maxHeightDiskCache: 2048, // HD cache
            cacheKey: imageUrl,
          );
        },
      ),
    );
  }

  Widget _shimmerPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(18),
      ),
      child: Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Container(
          height: height,
          width: double.infinity,
          color: theme.colorScheme.surfaceVariant,
          child: const Center(
            child: Icon(
              Icons.local_dining_outlined,
              color: AppColors.accent,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(18),
      ),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.85),
              AppColors.accent.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: height * 0.35,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black26),
                    Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black38),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
