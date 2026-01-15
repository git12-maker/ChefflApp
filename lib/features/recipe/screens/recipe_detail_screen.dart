import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../generate/widgets/ingredient_checklist.dart';
import '../../generate/widgets/instruction_steps.dart';
import '../../generate/widgets/recipe_stats_row.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/widgets/recipe_image.dart';
import '../../../core/constants/colors.dart';
import '../providers/recipe_display_provider.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            recipe.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/saved');
              }
            },
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeImage(
                title: recipe.title,
                imageUrl: recipe.imageUrl,
                height: 280,
                isLoading: false,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (recipe.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        recipe.description!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    RecipeStatsRow(
                      prepTime: recipe.prepTime,
                      cookTime: recipe.cookTime,
                      servings: null, // Removed - now in Adjust Recipe section
                      difficulty: recipe.difficulty,
                    ),
                    const SizedBox(height: 32),
                    // Servings and measurement unit controls
                    _RecipeControls(recipe: recipe),
                    const SizedBox(height: 24),
                    Text(
                      'Ingredients',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RecipeIngredients(recipe: recipe),
                    const SizedBox(height: 32),
                    Text(
                      'Instructions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InstructionSteps(steps: recipe.instructions),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.favorite_border_rounded),
                            label: const Text(
                              'Favorite',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.share_outlined),
                            label: const Text(
                              'Share',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Delete recipe',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                content: const Text(
                                  'Are you sure you want to delete this recipe?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (confirm) {
                          // For now just pop; deletion handled in Saved screen via provider.
                          if (context.mounted) {
                            context.pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
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

/// Widget for servings and measurement unit controls
class _RecipeControls extends ConsumerWidget {
  const _RecipeControls({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayState = ref.watch(recipeDisplayProvider(recipe));
    final displayNotifier = ref.read(recipeDisplayProvider(recipe).notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Adjust Recipe',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Servings selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Servings',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: displayState.displayServings > 1
                        ? () => displayNotifier.setServings(displayState.displayServings - 1)
                        : null,
                    iconSize: 24,
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '${displayState.displayServings}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => displayNotifier.setServings(displayState.displayServings + 1),
                    iconSize: 24,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Measurement unit selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.straighten_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Units',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              SegmentedButton<MeasurementUnit>(
                segments: const [
                  ButtonSegment<MeasurementUnit>(
                    value: MeasurementUnit.metric,
                    label: Text('Metric'),
                  ),
                  ButtonSegment<MeasurementUnit>(
                    value: MeasurementUnit.imperial,
                    label: Text('Imperial'),
                  ),
                ],
                selected: {displayState.measurementUnit},
                onSelectionChanged: (Set<MeasurementUnit> newSelection) {
                  displayNotifier.setMeasurementUnit(newSelection.first);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying ingredients with conversions
class _RecipeIngredients extends ConsumerWidget {
  const _RecipeIngredients({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayState = ref.watch(recipeDisplayProvider(recipe));
    // Use key to force rebuild when measurement unit changes
    return IngredientChecklist(
      key: ValueKey('${displayState.measurementUnit}_${displayState.displayServings}'),
      ingredients: displayState.ingredients,
    );
  }
}
