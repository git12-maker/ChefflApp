import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/recipe_preferences.dart';
import '../providers/generate_provider.dart';
import '../widgets/generate_button.dart';
import '../widgets/ingredient_chip.dart';
import '../widgets/ingredient_input.dart';
import '../widgets/preferences_panel.dart';
import '../widgets/smart_ingredient_selector.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {

  @override
  void initState() {
    super.initState();
    // Reset state when navigating to generate screen (unless ingredients are being set)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(generateProvider);
      // Always clear recipe when coming to generate screen (from refresh button or back navigation)
      // Only keep ingredients if they exist (coming from scan screen)
      if (state.generatedRecipe != null) {
        if (state.ingredients.isEmpty) {
          // No ingredients - clear everything (fresh start)
          ref.read(generateProvider.notifier).clearAll();
        } else {
          // Has ingredients - clear recipe but keep ingredients (from scan)
          ref.read(generateProvider.notifier).clearRecipe();
        }
      }
      // Reload user preferences to ensure defaults are up-to-date
      ref.read(generateProvider.notifier).reloadUserPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateProvider);
    final notifier = ref.read(generateProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's in your kitchen?"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add ingredients',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              IngredientInput(
                onAdd: notifier.addIngredient,
                hintText: 'e.g. chicken breast, garlic, lemon',
              ),
              const SizedBox(height: 12),
              
              // Selected ingredients
              if (state.ingredients.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.ingredients
                      .map(
                        (ingredient) => IngredientChip(
                          label: ingredient,
                          onRemoved: () => notifier.removeIngredient(ingredient),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Smart Ingredient Selector (always visible - shows Chef's Analysis when ingredients selected, browse always available)
              const SizedBox(height: 16),
              SmartIngredientSelector(
                selectedIngredients: state.ingredients,
                onAdd: notifier.addIngredient,
                onRemove: notifier.removeIngredient,
              ),
              
              const SizedBox(height: 16),
              PreferencesPanel(
                preferences: state.preferences,
                onChanged: notifier.updatePreferences,
              ),
              const SizedBox(height: 24),
              if (state.error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              GenerateButton(
                isLoading: state.isLoading,
                loadingLabel: state.loadingMessage,
                onPressed: () async {
                  // Navigate directly to loading screen
                  // The loading screen will start generation and show progress
                  if (context.mounted) {
                    context.go('/recipe-loading');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
