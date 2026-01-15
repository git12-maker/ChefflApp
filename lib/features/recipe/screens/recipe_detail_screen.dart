import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../generate/widgets/ingredient_checklist.dart';
import '../../generate/widgets/instruction_steps.dart';
import '../../generate/widgets/recipe_stats_row.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/widgets/recipe_image.dart';
import '../../../core/constants/colors.dart';

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
                      servings: recipe.servings,
                      difficulty: recipe.difficulty,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Ingredients',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    IngredientChecklist(ingredients: recipe.ingredients),
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
