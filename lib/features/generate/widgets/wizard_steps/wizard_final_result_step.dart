import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../widgets/smaakprofiel_visualisatie.dart';

/// Step 8: Final result
/// Matches app_voorstel_v2.md Scherm 8
class WizardFinalResultStep extends ConsumerWidget {
  const WizardFinalResultStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(smaakprofielWizardProvider);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    if (state.currentProfile == null || state.balanceAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build dish name
    final dishName = _buildDishName(state);

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
                'RESULTAAT',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  // TODO: Save recipe
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Dish name card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              dishName.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Flavor profile
          Text(
            'SMAAKPROFIEL',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          SmaakprofielVisualisatie(
            smaakprofiel: state.currentProfile!,
            balans: state.balanceAnalysis,
          ),
          
          const SizedBox(height: 32),
          
          // Balance checkmarks
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._getBalanceCheckmarks(state).map((check) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              check,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Drink suggestions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASSENDE DRANK:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🍷 Droge witte wijn (Sancerre)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '🍺 Witbier of Saison',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save recipe
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gerecht opgeslagen')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OPSLAAN',
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
              onPressed: () {
                notifier.reset();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
              child: const Text(
                'NIEUW GERECHT MAKEN',
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

  String _buildDishName(SmaakprofielWizardState state) {
    final parts = <String>[];
    
    if (state.mainIngredient != null && state.cookingMethod != null) {
      parts.add('${state.cookingMethod} ${state.mainIngredient!.name}');
    }
    
    if (state.additionalIngredients.isNotEmpty) {
      final additional = state.additionalIngredients
          .map((i) => i.name.toLowerCase())
          .join(', ');
      parts.add('met $additional');
    }
    
    return parts.join(' ');
  }

  List<String> _getBalanceCheckmarks(SmaakprofielWizardState state) {
    final checks = <String>[];
    final profile = state.currentProfile!;
    final strak = profile.mondgevoel.strak;
    final filmend = profile.mondgevoel.filmend;
    final ratio = filmend > 0 ? strak / filmend : 0;
    final type = profile.smaakrijkdom.type;

    if (ratio > 0.7 && ratio < 1.3) {
      checks.add('Goede balans strak/filmend');
    }
    
    if (type > 0.3 && type < 0.7) {
      checks.add('Combinatie fris én rijp');
    } else if (type > 0.7) {
      checks.add('Rijp smaakprofiel');
    } else {
      checks.add('Fris smaakprofiel');
    }
    
    if (profile.smaakrijkdom.gehalte > 0.6) {
      checks.add('Hoog smaakgehalte');
    }
    
    final umami = state.mainIngredient?.flavorProfile.umami ?? 0.0;
    if (umami > 0.5) {
      checks.add('Umami aanwezig');
    }

    return checks;
  }
}
