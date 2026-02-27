import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/ingredient.dart';

/// Visual ingredient card with image for selection
class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredient,
    this.isSelected = false,
    this.onTap,
    this.showBadge,
    this.badgeLabel,
  });

  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool? showBadge;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? AppColors.primary 
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ingredient image or placeholder
                  ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ingredient.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                  
                  // Selected overlay
                  if (isSelected)
                    Container(
                      color: AppColors.primary.withOpacity(0.2),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  
                  // Badge (e.g., "Carrier", "Umami", etc.)
                  if (showBadge == true && badgeLabel != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Name
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                ingredient.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            ingredient.name[0].toUpperCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
