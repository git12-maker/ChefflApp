import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smaakprofiel_wizard_provider.dart';
import '../widgets/wizard_steps/wizard_start_step.dart';
import '../widgets/wizard_steps/wizard_choose_main_ingredient_step.dart';
import '../widgets/wizard_steps/wizard_choose_cooking_method_step.dart';
import '../widgets/wizard_steps/wizard_first_profile_step.dart';
import '../widgets/wizard_steps/wizard_add_ingredients_step.dart';
import '../widgets/wizard_steps/wizard_add_ingredients_step_v2.dart';
import '../widgets/wizard_steps/wizard_preview_ingredient_step.dart';
import '../widgets/wizard_steps/wizard_updated_dish_step.dart';
import '../widgets/wizard_steps/wizard_updated_dish_step_v2.dart';
import '../widgets/wizard_steps/wizard_final_result_step.dart';
import '../widgets/wizard_progress_indicator.dart';

/// Main Smaakprofiel Wizard Screen
/// Follows the exact flow from app_voorstel_v2.md
/// Hides navbar during wizard for maximum space
class SmaakprofielWizardScreen extends ConsumerWidget {
  const SmaakprofielWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smaakprofielWizardProvider);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator (only show after step 1)
            if (state.currentStep != WizardStep.start)
              WizardProgressIndicator(
                currentStep: state.currentStep,
                onBack: state.canGoBack() ? () => notifier.goBack() : null,
              ),
            
            // Current step content
            Expanded(
              child: _buildStepContent(context, ref, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    WidgetRef ref,
    SmaakprofielWizardState state,
  ) {
    switch (state.currentStep) {
      case WizardStep.start:
        return const WizardStartStep();
      
      case WizardStep.chooseMainIngredient:
        return WizardChooseMainIngredientStep(
          category: state.selectedCategory!,
        );
      
      case WizardStep.chooseCookingMethod:
        return WizardChooseCookingMethodStep(
          ingredient: state.mainIngredient!,
        );
      
      case WizardStep.firstProfile:
        return const WizardFirstProfileStep();
      
      case WizardStep.addIngredients:
        return const WizardAddIngredientsStepV2();
      
      case WizardStep.previewIngredient:
        return WizardPreviewIngredientStep(
          ingredient: state.previewIngredient!,
        );
      
      case WizardStep.updatedDish:
        return const WizardUpdatedDishStepV2();
      
      case WizardStep.finalResult:
        return const WizardFinalResultStep();
    }
  }
}
