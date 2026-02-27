import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/smaakprofiel.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../widgets/smaakprofiel_visualisatie.dart';

/// Step 4: First flavor profile
/// Matches app_voorstel_v2.md Scherm 4
class WizardFirstProfileStep extends ConsumerWidget {
  const WizardFirstProfileStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(smaakprofielWizardProvider);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.currentProfile == null || state.balanceAnalysis == null) {
      return Center(
        child: Text(
          'Laden...',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final mainIngredient = state.mainIngredient!;
    final cookingMethod = state.cookingMethod!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'JOUW GERECHT',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Main ingredient display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '🐟 ${cookingMethod} ${mainIngredient.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Flavor profile visualization
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
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dit gerecht is nu:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getProfileDescription(state.currentProfile!),
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
          
          // Add ingredient button
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
        ],
      ),
    );
  }

  String _getProfileDescription(Smaakprofiel profile) {
    final strak = profile.mondgevoel.strak;
    final filmend = profile.mondgevoel.filmend;
    final type = profile.smaakrijkdom.type;

    if (filmend > 0.6) {
      if (type > 0.6) {
        return 'Vol en romig met rijpe tonen';
      } else {
        return 'Romig met frisse tonen';
      }
    } else if (strak > 0.6) {
      return 'Samentrekkend en fris';
    } else if (type > 0.7) {
      return 'Rijp en intens';
    } else if (type < 0.3) {
      return 'Fris en licht';
    }
    return 'Gebalanceerd';
  }
}
