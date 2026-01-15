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
import '../widgets/quick_add_grid.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  @override
  void initState() {
    super.initState();
    // Check if ingredients are already set in provider (from scan screen)
    // This happens when user navigates from scan screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentIngredients = ref.read(generateProvider).ingredients;
      // If ingredients are already set, we're good
      // Otherwise, they'll be set via route extra or manually
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateProvider);
    final notifier = ref.read(generateProvider.notifier);

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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              IngredientInput(
                onAdd: notifier.addIngredient,
                hintText: 'e.g. chicken breast, garlic, lemon',
              ),
              const SizedBox(height: 12),
              if (state.ingredients.isNotEmpty)
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
              Text(
                'Quick add',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              QuickAddGrid(onAdd: notifier.addIngredient),
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
