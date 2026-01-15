import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/widgets/recipe_image.dart';
import '../../../services/recipe_service.dart';
import '../../home/providers/home_provider.dart';
import '../../saved/providers/saved_provider.dart';
import '../providers/generate_provider.dart';
import '../widgets/ingredient_checklist.dart';
import '../widgets/instruction_steps.dart';
import '../widgets/recipe_stats_row.dart';

class RecipeResultScreen extends ConsumerWidget {
  const RecipeResultScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(generateProvider);
    final currentRecipe = state.generatedRecipe ?? recipe;
    final savedNotifier = ref.read(savedProvider.notifier);
    final homeNotifier = ref.read(homeProvider.notifier);
    final recipeService = RecipeService.instance;
    
    // Ensure image generation continues if recipe exists but image is missing
    // This handles navigation from loading screen before image is ready
    if (state.generatedRecipe != null && 
        state.generatedRecipe?.imageUrl == null && 
        !state.imageLoading) {
      // Start image generation in background
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ref.read(generateProvider.notifier).generateImage();
        }
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
            // Favorite button
            IconButton(
              icon: Icon(
                currentRecipe.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              onPressed: () async {
                // TODO: Implement favorite toggle via provider
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      currentRecipe.isFavorite
                          ? 'Removed from favorites'
                          : 'Added to favorites',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
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
              onPressed: () => context.go('/generate'),
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
                      servings: currentRecipe.servings,
                      difficulty: currentRecipe.difficulty,
                    ),
                    const SizedBox(height: 24),
                    Text('Ingredients', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    IngredientChecklist(ingredients: currentRecipe.ingredients),
                    const SizedBox(height: 24),
                    Text('Instructions', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    InstructionSteps(steps: currentRecipe.instructions),
                    const SizedBox(height: 24),
                    // Save and Share buttons (moved from bottom, now at top after content)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                // Create a clean recipe without id for new save
                                final recipeToSave = currentRecipe.copyWith(
                                  id: null, // Ensure no id for new recipe
                                );
                                
                                // Save the recipe to Supabase
                                await recipeService.saveRecipe(recipeToSave);
                                
                                // Refresh both saved and home providers
                                await Future.wait([
                                  savedNotifier.refresh(),
                                  homeNotifier.refresh(),
                                ]);
                                
                                // Show success message
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Recipe saved successfully!'),
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
                                  
                                  // Navigate to saved recipes
                                  context.go('/saved');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Failed to save recipe: ${e.toString()}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.favorite_border_rounded),
                            label: const Text(
                              'Save Recipe',
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
