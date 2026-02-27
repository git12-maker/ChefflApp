import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/widgets/recipe_image.dart';
import '../../../services/recipe_service.dart';
import '../../home/providers/home_provider.dart';
import '../../saved/providers/saved_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../recipe/providers/recipe_display_provider.dart';
import '../providers/generate_provider.dart';
import '../widgets/ingredient_checklist.dart';
import '../widgets/instruction_steps.dart';
import '../widgets/recipe_stats_row.dart';
import '../widgets/recipe_why_it_works.dart';

class RecipeResultScreen extends ConsumerStatefulWidget {
  const RecipeResultScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecipeResultScreen> createState() => _RecipeResultScreenState();
}

class _RecipeResultScreenState extends ConsumerState<RecipeResultScreen> {
  bool _isTogglingFavorite = false;
  bool _hasSyncedProviders = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(generateProvider);
    // Prefer state recipe over widget recipe (state is source of truth)
    // Only use widget.recipe if state doesn't have one (e.g., direct navigation)
    final currentRecipe = state.generatedRecipe ?? widget.recipe;
    final savedNotifier = ref.read(savedProvider.notifier);
    final homeNotifier = ref.read(homeProvider.notifier);
    final profileNotifier = ref.read(profileProvider.notifier);
    final recipeService = RecipeService.instance;
    
    // Ensure image generation continues if recipe exists but image is missing
    // This handles navigation from loading screen before image is ready
    if (state.generatedRecipe != null && 
        state.generatedRecipe!.imageUrl == null && 
        !state.imageLoading) {
      // Start image generation in background
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(generateProvider.notifier).generateImage();
        }
      });
    }

    // Sync providers when recipe is saved (has ID)
    if (currentRecipe.id != null && !_hasSyncedProviders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Refresh providers to sync data (silent refresh)
        savedNotifier.refresh();
        homeNotifier.refresh();
        profileNotifier.load();
        setState(() => _hasSyncedProviders = true);
      });
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentRecipe.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/generate');
              }
            },
          ),
          actions: [
            // Favorite button - toggle favorite status
            IconButton(
              icon: _isTogglingFavorite
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      currentRecipe.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: currentRecipe.isFavorite ? Colors.red : null,
                    ),
              onPressed: currentRecipe.id == null || _isTogglingFavorite
                  ? null
                  : () async {
                      if (currentRecipe.id == null) return;
                      
                      setState(() => _isTogglingFavorite = true);
                      
                      try {
                        final newFavoriteStatus = !currentRecipe.isFavorite;
                        
                        // Update favorite status in database
                        await recipeService.toggleFavorite(
                          currentRecipe.id!,
                          newFavoriteStatus,
                        );
                        
                        // Update generate provider state with new favorite status
                        final currentState = ref.read(generateProvider);
                        if (currentState.generatedRecipe != null) {
                          final updatedRecipe = currentState.generatedRecipe!.copyWith(
                            isFavorite: newFavoriteStatus,
                          );
                          ref.read(generateProvider.notifier).setGeneratedRecipe(updatedRecipe);
                        }
                        
                        // Refresh all providers to sync
                        await Future.wait([
                          savedNotifier.refresh(),
                          homeNotifier.refresh(),
                          profileNotifier.load(),
                        ]);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    newFavoriteStatus
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    newFavoriteStatus
                                        ? 'Added to favorites'
                                        : 'Removed from favorites',
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update favorite: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isTogglingFavorite = false);
                        }
                      }
                    },
              tooltip: currentRecipe.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
            // Share button
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share functionality coming soon!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Share recipe',
            ),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Clear the state completely before navigating
                ref.read(generateProvider.notifier).clearAll();
                // Navigate to generate screen without any extra data
                context.go('/generate', extra: null);
              },
              tooltip: 'Generate new recipe',
            ),
          ],
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeImage(
                title: currentRecipe.title,
                imageUrl: currentRecipe.imageUrl,
                isLoading: state.imageLoading,
                height: 230,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-saved indicator (if recipe has ID)
                    if (currentRecipe.id != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Saved automatically',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      currentRecipe.title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentRecipe.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentRecipe.description!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    RecipeStatsRow(
                      prepTime: currentRecipe.prepTime,
                      cookTime: currentRecipe.cookTime,
                      servings: null, // Removed - now in Adjust Recipe section
                      difficulty: currentRecipe.difficulty,
                    ),
                    const SizedBox(height: 24),
                    // Servings and measurement unit controls
                    _RecipeControls(recipe: currentRecipe),
                    const SizedBox(height: 24),
                    Text('Ingredients', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _RecipeIngredients(recipe: currentRecipe),
                    const SizedBox(height: 24),
                    // Why it works section
                    RecipeWhyItWorks(
                      recipe: currentRecipe,
                      ingredients: state.ingredients,
                    ),
                    const SizedBox(height: 24),
                    Text('Instructions', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    InstructionSteps(steps: currentRecipe.instructions),
                    const SizedBox(height: 24),
                    // Share button (removed Save button - auto-save handles it)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement share functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share functionality coming soon!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text(
                          'Share Recipe',
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
                    // Show image generation button if image is missing and not loading
                    // (fallback if automatic generation didn't start)
                    if (currentRecipe.imageUrl == null &&
                        !state.imageLoading) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(generateProvider.notifier).generateImage();
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Generate Image'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                    if (state.imageLoading) ...[
                      const SizedBox(height: 12),
                      Shimmer.fromColors(
                        baseColor: theme.colorScheme.surfaceVariant,
                        highlightColor: theme.colorScheme.surface,
                        child: const Text('Generating image...'),
                      ),
                    ] else if (state.imageError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.imageError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
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
