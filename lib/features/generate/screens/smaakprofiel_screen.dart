import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/ingredient.dart';
import '../../../shared/models/balans_analyse.dart';
import '../providers/smaakprofiel_provider.dart';
import '../providers/ingredient_provider.dart';
import '../widgets/selected_ingredients_bar.dart';
import '../widgets/smaakprofiel_visualisatie.dart';
import '../widgets/ingredient_picker_sheet.dart';
import 'dart:ui';

/// Main Smaakprofiel Screen
/// Replaces UltimateWizardScreen with focus on smaakprofiel composition
class SmaakprofielScreen extends ConsumerStatefulWidget {
  const SmaakprofielScreen({super.key});

  @override
  ConsumerState<SmaakprofielScreen> createState() => _SmaakprofielScreenState();
}

class _SmaakprofielScreenState extends ConsumerState<SmaakprofielScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure profile is calculated on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smaakprofielProvider.notifier).berekenProfiel();
    });
  }

  void _openIngredientPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: IngredientPickerSheet(
                  selectedIngredients: ref
                      .read(smaakprofielProvider)
                      .ingredienten
                      .map((i) => i.ingredient.name)
                      .toList(),
                  onAdd: (ingredientName) async {
                    // Get ingredient from provider state
                    final ingredientState = ref.read(ingredientProvider);
                    final allIngredients = ingredientState.allIngredients;
                    
                    if (allIngredients.isEmpty) {
                      // If not loaded, wait a bit and try again
                      await Future.delayed(const Duration(milliseconds: 500));
                      final updatedState = ref.read(ingredientProvider);
                      final updatedIngredients = updatedState.allIngredients;
                      if (updatedIngredients.isEmpty) return;
                      
                      final ingredient = updatedIngredients.firstWhere(
                        (i) => i.name.toLowerCase() == ingredientName.toLowerCase(),
                        orElse: () => updatedIngredients.firstWhere(
                          (i) => i.nameNl?.toLowerCase() == ingredientName.toLowerCase(),
                          orElse: () => updatedIngredients.first,
                        ),
                      );
                      
                      await ref
                          .read(smaakprofielProvider.notifier)
                          .voegIngredientToe(ingredient);
                    } else {
                      final ingredient = allIngredients.firstWhere(
                        (i) => i.name.toLowerCase() == ingredientName.toLowerCase(),
                        orElse: () => allIngredients.firstWhere(
                          (i) => i.nameNl?.toLowerCase() == ingredientName.toLowerCase(),
                          orElse: () => allIngredients.first,
                        ),
                      );

                      // Add to smaakprofiel
                      await ref
                          .read(smaakprofielProvider.notifier)
                          .voegIngredientToe(ingredient);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeIngredient(String ingredientId) {
    ref.read(smaakprofielProvider.notifier).verwijderIngredient(ingredientId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smaakprofielProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Smaakprofiel',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (state.ingredienten.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.read(smaakprofielProvider.notifier).clearAll();
                      },
                      tooltip: 'Reset',
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected ingredients bar
                    SelectedIngredientsBar(
                      ingredients: state.ingredienten
                          .map((i) => i.ingredient.name)
                          .toList(),
                      onRemove: (ingredientName) {
                        final ingredient = state.ingredienten.firstWhere(
                          (i) => i.ingredient.name == ingredientName,
                        );
                        _removeIngredient(ingredient.ingredient.id);
                      },
                      onAddPressed: _openIngredientPicker,
                      emptyTitle: 'Start met een hoofdingrediënt',
                      emptySubtitle:
                          'Kies je basis eerst (eiwit, graan of groente).',
                    ),

                    const SizedBox(height: 24),

                    // Smaakprofiel visualization
                    if (state.gecombineerdProfiel != null)
                      SmaakprofielVisualisatie(
                        smaakprofiel: state.gecombineerdProfiel!,
                        balans: state.balans,
                      )
                    else if (state.ingredienten.isNotEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      _buildEmptyState(context),

                    const SizedBox(height: 24),

                    // Suggestions
                    if (state.balans != null &&
                        state.balans!.ontbrekendeElementen.isNotEmpty) ...[
                      _buildSuggestionsSection(context, state),
                      const SizedBox(height: 24),
                    ],

                    // Error message
                    if (state.error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Begin met ingrediënten',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voeg ingrediënten toe om je smaakprofiel te zien',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(
    BuildContext context,
    SmaakprofielState state,
  ) {
    final theme = Theme.of(context);
    final balans = state.balans!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggesties',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...balans.ontbrekendeElementen.map((element) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      element.priority == MissingPriority.high
                          ? Icons.priority_high
                          : Icons.info_outline,
                      size: 16,
                      color: element.priority == MissingPriority.high
                          ? AppColors.error
                          : AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            element.reason,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (element.suggestie != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Suggestie: ${element.suggestie}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
