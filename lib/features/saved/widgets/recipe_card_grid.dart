import 'package:flutter/material.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/widgets/recipe_image.dart';
import '../../../core/constants/colors.dart';

class RecipeCardGrid extends StatelessWidget {
  const RecipeCardGrid({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.xlargeAll,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppBorderRadius.xlargeAll,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed height image - always 160px
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.xlarge),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: RecipeImage(
                    title: recipe.title,
                    imageUrl: recipe.imageUrl,
                    height: 160,
                    isLoading: false,
                  ),
                ),
              ),
              // Content section - constrained padding
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row with favorite button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onFavoriteToggle,
                            borderRadius: AppBorderRadius.smallAll,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              child: Icon(
                                recipe.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: recipe.isFavorite
                                    ? AppColors.primary
                                    : theme.iconTheme.color?.withOpacity(0.6),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stat chips - wrapped to prevent overflow
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (recipe.cookTime != null || recipe.prepTime != null)
                          _StatChip(
                            icon: Icons.timer_outlined,
                            label:
                                '${(recipe.prepTime ?? 0) + (recipe.cookTime ?? 0)}m',
                          ),
                        if (recipe.difficulty != null)
                          _StatChip(
                            icon: Icons.terrain_outlined,
                            label: recipe.difficulty!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: AppBorderRadius.smallAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
