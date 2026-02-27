import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/cooking_methods_service.dart';
import '../../../shared/models/ingredient.dart';

/// Preview of how cooking method transforms an ingredient
class CookingEffectPreview extends StatelessWidget {
  const CookingEffectPreview({
    super.key,
    required this.effect,
    required this.baseIngredient,
  });

  final CookingEffect effect;
  final Ingredient baseIngredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Effects of ${effect.cookingMethod.nameEn}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Flavor changes
          if (effect.flavorDelta != null) ...[
            _buildFlavorChanges(context),
            const SizedBox(height: 12),
          ],
          
          // Aroma changes
          if (effect.aromaCategoriesAdded.isNotEmpty || 
              effect.aromaCategoriesRemoved.isNotEmpty) ...[
            _buildAromaChanges(context),
            const SizedBox(height: 12),
          ],
          
          // Texture changes
          if (effect.textureCategoriesAdded.isNotEmpty ||
              effect.textureCategoriesRemoved.isNotEmpty) ...[
            _buildTextureChanges(context),
            const SizedBox(height: 12),
          ],
          
          // Scientific reactions
          if (effect.maillardContribution > 0.3 || 
              effect.caramelizationContribution > 0.3) ...[
            _buildScientificReactions(context),
            const SizedBox(height: 12),
          ],
          
          // Optimal conditions
          if (effect.optimalTemperature != null || effect.optimalTimeMin != null)
            _buildOptimalConditions(context),
        ],
      ),
    );
  }

  Widget _buildFlavorChanges(BuildContext context) {
    final theme = Theme.of(context);
    final delta = effect.flavorDelta!;
    final changes = <String>[];
    
    if (delta.umami > 0.1) {
      changes.add('+${(delta.umami * 100).toStringAsFixed(0)}% umami');
    }
    if (delta.sweetness > 0.1) {
      changes.add('+${(delta.sweetness * 100).toStringAsFixed(0)}% sweetness');
    }
    if (delta.sourness < -0.1) {
      changes.add('${(delta.sourness * 100).toStringAsFixed(0)}% sourness');
    }
    
    if (changes.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.restaurant_menu_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Flavor: ${changes.join(", ")}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildAromaChanges(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    
    if (effect.aromaCategoriesAdded.isNotEmpty) {
      parts.add('Adds ${effect.aromaCategoriesAdded.join(", ")}');
    }
    if (effect.aromaCategoriesRemoved.isNotEmpty) {
      parts.add('Removes ${effect.aromaCategoriesRemoved.join(", ")}');
    }
    
    if (parts.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.air_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Aroma: ${parts.join(". ")}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildTextureChanges(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    
    if (effect.textureCategoriesAdded.isNotEmpty) {
      parts.add('Becomes ${effect.textureCategoriesAdded.join(", ")}');
    }
    if (effect.textureCategoriesRemoved.isNotEmpty) {
      parts.add('Loses ${effect.textureCategoriesRemoved.join(", ")}');
    }
    
    if (parts.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.texture_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Texture: ${parts.join(". ")}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildScientificReactions(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    
    if (effect.maillardContribution > 0.5) {
      parts.add('Strong Maillard reaction (browning, umami)');
    } else if (effect.maillardContribution > 0.3) {
      parts.add('Maillard reaction (browning)');
    }
    
    if (effect.caramelizationContribution > 0.5) {
      parts.add('Strong caramelization (sweetness, golden color)');
    } else if (effect.caramelizationContribution > 0.3) {
      parts.add('Caramelization (sweetness)');
    }
    
    if (parts.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.science_rounded,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join('. '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptimalConditions(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[];
    
    if (effect.optimalTemperature != null) {
      parts.add('${effect.optimalTemperature}°C');
    }
    if (effect.optimalTimeMin != null) {
      parts.add('${effect.optimalTimeMin} min');
    }
    
    if (parts.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.timer_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Optimal: ${parts.join(", ")}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
