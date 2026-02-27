import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/generate_provider.dart';

/// Compact square ingredient card with instant feedback
class IngredientFeedbackCard extends ConsumerWidget {
  const IngredientFeedbackCard({
    super.key,
    required this.ingredient,
    this.isSelected = false,
    this.onTap,
    this.showMoleculeInfo = false,
  });

  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showMoleculeInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cookingMethod = ref.watch(generateProvider).cookingMethods[ingredient.name];
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ingredient.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(context),
                      errorWidget: (context, url, error) => _buildPlaceholder(context),
                    )
                  : _buildPlaceholder(context),
              
              // Gradient overlay for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        ingredient.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Molecule info
                      if (showMoleculeInfo) ...[
                        const SizedBox(height: 2),
                        _buildMoleculeBadge(context),
                      ],
                      // Aroma categories (compact, if available)
                      if (ingredient.aromaCategories.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _buildAromaBadge(context),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Cooking method badge (top left)
              if (cookingMethod != null && cookingMethod.isNotEmpty && cookingMethod != 'Raw')
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          cookingMethod,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_rounded,
              size: 32,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 4),
            Text(
              ingredient.name[0].toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoleculeBadge(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    Color color;
    
    switch (ingredient.moleculeType) {
      case MoleculeType.water:
        label = '💧 Water';
        color = Colors.blue;
        break;
      case MoleculeType.fat:
        label = '🧈 Fat';
        color = Colors.amber;
        break;
      case MoleculeType.carbohydrate:
        label = '🌾 Carbs';
        color = Colors.orange;
        break;
      case MoleculeType.protein:
        label = '🥩 Protein';
        color = Colors.red;
        break;
      default:
        label = 'Mixed';
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAromaBadge(BuildContext context) {
    final theme = Theme.of(context);
    final firstCategory = ingredient.aromaCategories.first;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        firstCategory,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
