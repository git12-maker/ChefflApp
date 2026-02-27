import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/ingredient.dart';
import '../../../../shared/models/smaakprofiel.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../../../services/smaakprofiel_service.dart';

/// Step 6: Preview ingredient effect
/// Matches app_voorstel_v2.md Scherm 6
class WizardPreviewIngredientStep extends ConsumerWidget {
  final Ingredient ingredient;

  const WizardPreviewIngredientStep({
    super.key,
    required this.ingredient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(smaakprofielWizardProvider);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    // Calculate what this ingredient would add
    final ingredientProfile = _calculateIngredientProfile(ingredient);
    final potentialProfile = _calculatePotentialProfile(state, ingredientProfile);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            ingredient.name.toUpperCase(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // What ingredient adds
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WAT ${ingredient.name.toUpperCase()} TOEVOEGT:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mondgevoel changes
                _buildEffectRow(
                  context,
                  'Mondgevoel Strak',
                  ingredientProfile.mondgevoel.strak * 100,
                  'samentrekkend',
                ),
                _buildEffectRow(
                  context,
                  'Mondgevoel Filmend',
                  ingredientProfile.mondgevoel.filmend * 100,
                  'laagje achterlatend',
                ),
                _buildEffectRow(
                  context,
                  'Mondgevoel Droog',
                  ingredientProfile.mondgevoel.droog * 100,
                  'vocht absorberend',
                ),
                const SizedBox(height: 16),
                _buildEffectRow(
                  context,
                  'Smaakgehalte',
                  ingredientProfile.smaakrijkdom.gehalte * 100,
                  'intensiteit',
                ),
                _buildEffectRow(
                  context,
                  'Smaaktype',
                  ingredientProfile.smaakrijkdom.type * 100,
                  ingredientProfile.smaakrijkdom.type < 0.3
                      ? 'fris'
                      : (ingredientProfile.smaakrijkdom.type > 0.7 ? 'rijp' : 'neutraal'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Your dish becomes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOUW GERECHT WORDT:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getPotentialDescription(potentialProfile),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEffectRow(
                  context,
                  'Strak',
                  potentialProfile.mondgevoel.strak * 100,
                  '',
                ),
                _buildEffectRow(
                  context,
                  'Filmend',
                  potentialProfile.mondgevoel.filmend * 100,
                  '',
                ),
                _buildEffectRow(
                  context,
                  'Droog',
                  potentialProfile.mondgevoel.droog * 100,
                  '',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await notifier.addIngredient(ingredient);
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
                '✓ TOEVOEGEN',
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

  Widget _buildEffectRow(
    BuildContext context,
    String label,
    double value,
    String description,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.grey300,
              color: AppColors.accent,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '${value.round()}% $description',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Smaakprofiel _calculateIngredientProfile(Ingredient ing) {
    // Calculate from ingredient properties
    final strak = ing.mouthfeel == MouthfeelCategory.astringent
        ? 0.8
        : (ing.flavorProfile.sourness > 0.5 ? 0.7 : 0.1);
    final filmend = ing.mouthfeel == MouthfeelCategory.coating
        ? 0.8
        : (ing.mouthfeel == MouthfeelCategory.rich ? 0.7 : 0.1);
    final droog = ing.mouthfeel == MouthfeelCategory.dry ? 0.8 : 0.1;

    final type = ing.aromaCategories.contains('citrus') ||
            ing.aromaCategories.contains('fresh')
        ? 0.2
        : (ing.aromaCategories.contains('roasted') ||
                ing.aromaCategories.contains('caramel')
            ? 0.8
            : 0.5);

    return Smaakprofiel(
      mondgevoel: Mondgevoel(
        strak: strak,
        filmend: filmend,
        droog: droog,
      ),
      smaakrijkdom: Smaakrijkdom(
        gehalte: ing.aromaIntensity,
        type: type,
      ),
    );
  }

  Smaakprofiel _calculatePotentialProfile(
    SmaakprofielWizardState state,
    Smaakprofiel ingredientProfile,
  ) {
    if (state.currentProfile == null) return ingredientProfile;

    // Simple weighted average (ingredient is supporting, so lower weight)
    final mainWeight = 100.0;
    final ingredientWeight = 15.0;
    final totalWeight = mainWeight + ingredientWeight;

    final mainFactor = mainWeight / totalWeight;
    final ingFactor = ingredientWeight / totalWeight;

    return Smaakprofiel(
      mondgevoel: Mondgevoel(
        strak: (state.currentProfile!.mondgevoel.strak * mainFactor) +
            (ingredientProfile.mondgevoel.strak * ingFactor),
        filmend: (state.currentProfile!.mondgevoel.filmend * mainFactor) +
            (ingredientProfile.mondgevoel.filmend * ingFactor),
        droog: (state.currentProfile!.mondgevoel.droog * mainFactor) +
            (ingredientProfile.mondgevoel.droog * ingFactor),
      ),
      smaakrijkdom: Smaakrijkdom(
        gehalte: (state.currentProfile!.smaakrijkdom.gehalte * mainFactor) +
            (ingredientProfile.smaakrijkdom.gehalte * ingFactor),
        type: (state.currentProfile!.smaakrijkdom.type * mainFactor) +
            (ingredientProfile.smaakrijkdom.type * ingFactor),
      ),
    );
  }

  String _getPotentialDescription(Smaakprofiel profile) {
    final strak = profile.mondgevoel.strak;
    final filmend = profile.mondgevoel.filmend;
    final type = profile.smaakrijkdom.type;

    if ((strak - filmend).abs() < 0.2) {
      return 'Vol én fris - beter in balans';
    } else if (filmend > 0.6) {
      return 'Romig en vol';
    } else if (strak > 0.6) {
      return 'Fris en strak';
    }
    return 'Gebalanceerd';
  }
}
