import 'package:flutter/material.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/widgets/recipe_image.dart';
import '../../../core/constants/colors.dart';

/// Recipe card for horizontal scroll - fixed dimensions, no overflow
class RecipeCardHorizontal extends StatelessWidget {
  const RecipeCardHorizontal({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  final Recipe recipe;
  final VoidCallback onTap;

  static const double cardWidth = 200;
  static const double imageHeight = 130;
  static const double contentHeight = 76;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.large),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppBorderRadius.large),
                  ),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: RecipeImage(
                      title: recipe.title,
                      imageUrl: recipe.imageUrl,
                      height: imageHeight,
                      isLoading: false,
                    ),
                  ),
                ),
                SizedBox(
                  height: contentHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (recipe.cookTime != null || recipe.prepTime != null)
                              _StatPill(
                                label: '${(recipe.prepTime ?? 0) + (recipe.cookTime ?? 0)} min',
                              ),
                            if (recipe.difficulty != null) ...[
                              const SizedBox(width: 8),
                              _StatPill(label: recipe.difficulty!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
