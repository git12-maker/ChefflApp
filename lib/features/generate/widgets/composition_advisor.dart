import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';

/// Widget showing composition analysis and what's missing for a complete dish
class CompositionAdvisor extends StatelessWidget {
  const CompositionAdvisor({
    super.key,
    required this.analysis,
    required this.onSuggestionTap,
  });

  final CompositionAnalysis analysis;
  final void Function(String ingredientName) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score indicator
        _buildScoreHeader(context),
        const SizedBox(height: 16),
        
        // Missing elements
        if (analysis.missingElements.isNotEmpty) ...[
          _buildMissingElements(context),
          const SizedBox(height: 16),
        ],
        
        // Smart suggestions
        if (analysis.suggestions.isNotEmpty) ...[
          Text(
            'Suggested additions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSuggestions(context),
        ],
        
        // Carrier info
        if (analysis.carrier != null) ...[
          const SizedBox(height: 16),
          _buildCarrierInfo(context),
        ],
        
        // Visual presentation analysis
        if (analysis.visualPresentation != null) ...[
          const SizedBox(height: 16),
          _buildVisualPresentation(context),
        ],
      ],
    );
  }

  Widget _buildScoreHeader(BuildContext context) {
    final theme = Theme.of(context);
    final score = analysis.overallScore;
    
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Well composed';
      scoreIcon = Icons.restaurant_menu;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good start';
      scoreIcon = Icons.auto_awesome;
    } else {
      scoreColor = Colors.red.shade400;
      scoreLabel = 'Needs more';
      scoreIcon = Icons.add_circle_outline;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withOpacity(0.15),
            scoreColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              scoreIcon,
              color: scoreColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scoreLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scoreColor,
                  ),
                ),
                Text(
                  'Composition score: $score/100',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Circular progress indicator
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    '$score',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingElements(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: Colors.amber,
            ),
            const SizedBox(width: 8),
            Text(
              'What your dish needs',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.missingElements.map((missing) {
            return _MissingElementChip(
              element: missing,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: analysis.suggestions.map((suggestion) {
        return _SuggestionChip(
          suggestion: suggestion,
          onTap: () => onSuggestionTap(suggestion.ingredient.name),
        );
      }).toList(),
    );
  }

  Widget _buildCarrierInfo(BuildContext context) {
    final theme = Theme.of(context);
    final carrier = analysis.carrier!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main element: ${carrier.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'The carrier around which your dish is built',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPresentation(BuildContext context) {
    final theme = Theme.of(context);
    final visual = analysis.visualPresentation!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Visual Presentation',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Color palette
          if (visual.colorPalette.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Colors: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: visual.colorPalette.map((color) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        color,
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Plating principles
          _buildPlatingPrinciple(
            context,
            'Color contrast',
            visual.hasColorContrast,
            Icons.contrast,
          ),
          const SizedBox(height: 6),
          _buildPlatingPrinciple(
            context,
            'Odd number elements',
            visual.hasOddNumberElements,
            Icons.numbers,
          ),
          const SizedBox(height: 6),
          _buildPlatingPrinciple(
            context,
            'Garnish potential',
            visual.hasGarnishPotential,
            Icons.eco,
          ),
          
          // Suggestions
          if (visual.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...visual.suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPlatingPrinciple(
    BuildContext context,
    String label,
    bool isGood,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          isGood ? Icons.check_circle_outline : Icons.info_outline,
          size: 16,
          color: isGood ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 6),
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MissingElementChip extends StatelessWidget {
  const _MissingElementChip({required this.element});

  final MissingElement element;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final color = _getElementColor(element.type);
    final icon = _getElementIcon(element.type);
    final label = _getElementLabel(element.type);
    
    return Tooltip(
      message: element.reason,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (element.priority == MissingPriority.high) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.priority_high,
                size: 12,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getElementColor(ElementType type) {
    switch (type) {
      case ElementType.carrier:
        return Colors.deepPurple;
      case ElementType.umami:
        return Colors.purple;
      case ElementType.acid:
        return Colors.amber;
      case ElementType.texture:
      case ElementType.crunch:
        return Colors.teal;
      case ElementType.freshness:
        return Colors.green;
      case ElementType.richness:
        return Colors.orange;
      case ElementType.aroma:
        return Colors.indigo;
      case ElementType.mouthfeel:
        return Colors.pink;
      case ElementType.cookingMethod:
        return Colors.brown;
    }
  }

  IconData _getElementIcon(ElementType type) {
    switch (type) {
      case ElementType.carrier:
        return Icons.restaurant;
      case ElementType.umami:
        return Icons.auto_awesome;
      case ElementType.acid:
        return Icons.brightness_high;
      case ElementType.texture:
      case ElementType.crunch:
        return Icons.grain;
      case ElementType.freshness:
        return Icons.spa;
      case ElementType.richness:
        return Icons.water_drop;
      case ElementType.aroma:
        return Icons.air;
      case ElementType.mouthfeel:
        return Icons.sentiment_satisfied;
      case ElementType.cookingMethod:
        return Icons.restaurant_menu;
    }
  }

  String _getElementLabel(ElementType type) {
    switch (type) {
      case ElementType.carrier:
        return 'Main element';
      case ElementType.umami:
        return 'Umami';
      case ElementType.acid:
        return 'Acidity';
      case ElementType.texture:
        return 'Texture';
      case ElementType.crunch:
        return 'Crunch';
      case ElementType.freshness:
        return 'Freshness';
      case ElementType.richness:
        return 'Richness';
      case ElementType.aroma:
        return 'Aroma';
      case ElementType.mouthfeel:
        return 'Mouthfeel';
      case ElementType.cookingMethod:
        return 'Cooking method';
    }
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final IngredientSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Tooltip(
      message: suggestion.optimalCookingMethod != null
          ? '${suggestion.reason}\n\nRecommended: ${suggestion.optimalCookingMethod}'
          : suggestion.reason,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primaryDark.withOpacity(0.15),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.accent.withOpacity(0.05),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      suggestion.ingredient.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (suggestion.optimalCookingMethod != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 12,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggestion.optimalCookingMethod!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary.withOpacity(0.7),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
