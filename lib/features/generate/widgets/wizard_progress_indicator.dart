import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../providers/smaakprofiel_wizard_provider.dart';

/// Progress indicator for wizard steps
/// Shows current step and back button
class WizardProgressIndicator extends StatelessWidget {
  final WizardStep currentStep;
  final VoidCallback? onBack;

  const WizardProgressIndicator({
    super.key,
    required this.currentStep,
    this.onBack,
  });

  int _getStepNumber(WizardStep step) {
    switch (step) {
      case WizardStep.start:
        return 0;
      case WizardStep.chooseMainIngredient:
        return 1;
      case WizardStep.chooseCookingMethod:
        return 2;
      case WizardStep.firstProfile:
        return 3;
      case WizardStep.addIngredients:
        return 4;
      case WizardStep.previewIngredient:
        return 4; // Same as add ingredients
      case WizardStep.updatedDish:
        return 4; // Same as add ingredients
      case WizardStep.finalResult:
        return 5;
    }
  }

  String _getStepTitle(WizardStep step) {
    switch (step) {
      case WizardStep.start:
        return 'Start';
      case WizardStep.chooseMainIngredient:
        return 'Hoofdingrediënt';
      case WizardStep.chooseCookingMethod:
        return 'Bereiden';
      case WizardStep.firstProfile:
        return 'Smaakprofiel';
      case WizardStep.addIngredients:
        return 'Toevoegen';
      case WizardStep.previewIngredient:
        return 'Preview';
      case WizardStep.updatedDish:
        return 'Bijgewerkt';
      case WizardStep.finalResult:
        return 'Resultaat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepNumber = _getStepNumber(currentStep);
    final totalSteps = 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
              tooltip: 'Terug',
            )
          else
            const SizedBox(width: 48),
          
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: stepNumber / totalSteps,
                        backgroundColor: AppColors.grey300,
                        color: AppColors.primary,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${stepNumber}/$totalSteps',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepTitle(currentStep),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
