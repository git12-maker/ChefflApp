import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../widgets/smaakprofiel_visualisatie.dart';

/// Step 7: Updated dish view
/// Matches app_voorstel_v2.md Scherm 7
class WizardUpdatedDishStep extends ConsumerWidget {
  const WizardUpdatedDishStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(smaakprofielWizardProvider);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    if (state.currentProfile == null || state.balanceAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'JOUW GERECHT',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle),
                color: AppColors.primary,
                onPressed: () => notifier.finishDish(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Ingredients list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.mainIngredient != null && state.cookingMethod != null)
                  Text(
                    '🐟 ${state.cookingMethod} ${state.mainIngredient!.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ...state.additionalIngredients.map((ing) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '🍋 + ${ing.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Flavor profile
          SmaakprofielVisualisatie(
            smaakprofiel: state.currentProfile!,
            balans: state.balanceAnalysis,
          ),
          
          const SizedBox(height: 32),
          
          // Feedback
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Goed bezig!',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getFeedback(state),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Missing elements
          if (state.balanceAnalysis!.ontbrekendeElementen.isNotEmpty) ...[
            Text(
              'Wat mist er misschien?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...state.balanceAnalysis!.ontbrekendeElementen.map((element) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text('→ '),
                      Expanded(
                        child: Text(
                          element.reason,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],
          
          // Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => notifier.goToAddIngredients(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '+ INGREDIËNT TOEVOEGEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => notifier.finishDish(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
              child: const Text(
                '✓ GERECHT AFRONDEN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeedback(SmaakprofielWizardState state) {
    final profile = state.currentProfile!;
    final strak = profile.mondgevoel.strak;
    final filmend = profile.mondgevoel.filmend;
    final ratio = filmend > 0 ? strak / filmend : 0;

    if (ratio > 0.7 && ratio < 1.3) {
      return 'Je hebt nu balans tussen romig en fris. Wil je textuur toevoegen?';
    } else if (filmend > 0.6) {
      return 'Romig gerecht. Overweeg iets fris toe te voegen.';
    } else if (strak > 0.6) {
      return 'Fris gerecht. Overweeg iets romigs toe te voegen.';
    }
    return 'Gerecht is in ontwikkeling. Voeg ingrediënten toe voor meer balans.';
  }
}
