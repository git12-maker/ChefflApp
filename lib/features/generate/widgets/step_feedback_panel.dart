import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/generate_provider.dart';

/// Panel showing feedback when ingredient is added
class StepFeedbackPanel extends ConsumerWidget {
  const StepFeedbackPanel({
    super.key,
    required this.ingredient,
    required this.analysis,
    this.onDismiss,
  });

  final Ingredient ingredient;
  final CompositionAnalysis analysis;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cookingMethod = ref.watch(generateProvider).cookingMethods[ingredient.name];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ingredient.name} added',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Cooking method (if selected)
          if (cookingMethod != null && cookingMethod.isNotEmpty && cookingMethod != 'Raw') ...[
            _buildInfoRow(
              context,
              'Cooking method:',
              cookingMethod,
              valueColor: AppColors.primary,
            ),
            const SizedBox(height: 8),
          ],
          
          // What this adds
          _buildInfoRow(
            context,
            'What this adds:',
            _getIngredientContribution(ingredient),
          ),
          const SizedBox(height: 8),
          
          // Aroma info (if available)
          if (ingredient.aromaCategories.isNotEmpty) ...[
            _buildInfoRow(
              context,
              'Aroma:',
              ingredient.aromaCategories.join(', '),
            ),
            const SizedBox(height: 8),
          ],
          
          // Texture info (if available)
          if (ingredient.textures.isNotEmpty) ...[
            _buildInfoRow(
              context,
              'Texture:',
              ingredient.textures.map((t) => t.name).join(', '),
            ),
            const SizedBox(height: 8),
          ],
          
          // Current composition
          _buildInfoRow(
            context,
            'Current score:',
            '${analysis.overallScore}/100',
            valueColor: _getScoreColor(analysis.overallScore),
          ),
          
          // Missing elements
          if (analysis.missingElements.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMissingElements(context, analysis.missingElements),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: valueColor ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingElements(
    BuildContext context,
    List<MissingElement> missing,
  ) {
    final theme = Theme.of(context);
    // Show all high priority missing elements, not just a limited subset
    final highPriority = missing.where((e) => e.priority == MissingPriority.high);
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: highPriority.map((element) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                element.reason,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getIngredientContribution(Ingredient ingredient) {
    final contributions = <String>[];
    
    // Molecule type
    switch (ingredient.moleculeType) {
      case MoleculeType.water:
        contributions.add('moisture & freshness');
        break;
      case MoleculeType.fat:
        contributions.add('richness & flavor carrier');
        break;
      case MoleculeType.carbohydrate:
        contributions.add('energy & structure');
        break;
      case MoleculeType.protein:
        contributions.add('satisfaction & umami');
        break;
      default:
        break;
    }
    
    // Flavor contributions
    if (ingredient.providesUmami) {
      contributions.add('umami depth');
    }
    if (ingredient.providesAcidity) {
      contributions.add('brightness');
    }
    if (ingredient.providesCrunch) {
      contributions.add('texture');
    }
    
    // Role
    if (ingredient.canBeCarrier) {
      contributions.add('main element');
    }
    
    return contributions.isEmpty 
        ? 'flavor & nutrition'
        : contributions.join(', ');
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
