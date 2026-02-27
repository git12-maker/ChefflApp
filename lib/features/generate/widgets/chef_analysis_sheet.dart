import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../providers/generate_provider.dart';
import 'composition_advisor.dart';
import 'flavor_balance_indicator.dart';

class ChefAnalysisSheet extends ConsumerWidget {
  const ChefAnalysisSheet({
    super.key,
    required this.analysis,
    required this.onAddIngredient,
  });

  final CompositionAnalysis analysis;
  final void Function(String ingredientName) onAddIngredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cookingMethods = ref.watch(generateProvider).cookingMethods;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chef Analysis',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlavorBalanceIndicator(flavorProfile: analysis.flavorProfile),
                  const SizedBox(height: 16),
                  
                  // Cooking methods section (if any are selected)
                  if (cookingMethods.isNotEmpty) ...[
                    _buildCookingMethodsSection(context, theme, cookingMethods, analysis),
                    const SizedBox(height: 16),
                  ],
                  
                  CompositionAdvisor(
                    analysis: analysis,
                    onSuggestionTap: onAddIngredient,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookingMethodsSection(
    BuildContext context,
    ThemeData theme,
    Map<String, String> cookingMethods,
    CompositionAnalysis analysis,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Cooking Methods',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cookingMethods.entries.map((entry) {
              if (entry.value == 'Raw' || entry.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Chip(
                avatar: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: Text('${entry.key}: ${entry.value}'),
                labelStyle: theme.textTheme.labelSmall,
                backgroundColor: theme.colorScheme.primaryContainer,
              );
            }).where((chip) => chip is! SizedBox).toList(),
          ),
          if (cookingMethods.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Analysis is based on "as prepared" state with these cooking methods applied.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

