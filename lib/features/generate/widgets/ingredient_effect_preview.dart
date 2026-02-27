import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/ingredient.dart';
import '../../../shared/models/smaakprofiel.dart';
import '../../../services/smaakprofiel_service.dart';

/// Ingredient Effect Preview Widget
/// Shows what an ingredient will add to the smaakprofiel BEFORE adding it
class IngredientEffectPreview extends StatelessWidget {
  const IngredientEffectPreview({
    super.key,
    required this.ingredient,
    required this.currentProfiel,
    this.cookingMethod,
  });

  final Ingredient ingredient;
  final Smaakprofiel currentProfiel;
  final String? cookingMethod;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Smaakprofiel>(
      future: SmaakprofielService.instance.getSmaakprofiel(
        ingredient.id,
        cookingMethod: cookingMethod,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final ingredientProfiel = snapshot.data!;
        final newProfiel = _calculateNewProfiel(currentProfiel, ingredientProfiel);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WAT ${ingredient.name.toUpperCase()} TOEVOEGT:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mondgevoel changes
              _buildMondgevoelChange(
                context,
                'Strak',
                currentProfiel.mondgevoel.strak,
                newProfiel.mondgevoel.strak,
                _strakColor,
              ),
              const SizedBox(height: 12),
              _buildMondgevoelChange(
                context,
                'Filmend',
                currentProfiel.mondgevoel.filmend,
                newProfiel.mondgevoel.filmend,
                _filmendColor,
              ),
              const SizedBox(height: 12),
              _buildMondgevoelChange(
                context,
                'Droog',
                currentProfiel.mondgevoel.droog,
                newProfiel.mondgevoel.droog,
                _droogColor,
              ),
              const SizedBox(height: 16),

              // Smaaktype change
              _buildSmaaktypeChange(
                context,
                currentProfiel.smaakrijkdom.type,
                newProfiel.smaakrijkdom.type,
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'JOUW GERECHT WORDT:',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generateDescription(newProfiel),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMondgevoelChange(
    BuildContext context,
    String label,
    double current,
    double newValue,
    Color color,
  ) {
    final delta = newValue - current;
    final deltaPercent = (delta * 100).round();
    final isIncrease = delta > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (delta != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncrease
                      ? color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isIncrease ? color : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isIncrease ? '+' : ''}${deltaPercent}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isIncrease ? color : Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildProgressBar(context, current, color, opacity: 0.3),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProgressBar(context, newValue, color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    double value,
    Color color, {
    double opacity = 1.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        valueColor: AlwaysStoppedAnimation<Color>(
          color.withOpacity(opacity),
        ),
      ),
    );
  }

  Widget _buildSmaaktypeChange(
    BuildContext context,
    double current,
    double newValue,
  ) {
    final theme = Theme.of(context);
    final currentDesc = current < 0.3
        ? 'Fris'
        : current < 0.7
            ? 'Neutraal'
            : 'Rijp';
    final newDesc = newValue < 0.3
        ? 'Fris'
        : newValue < 0.7
            ? 'Neutraal'
            : 'Rijp';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smaaktype',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeIndicator(context, current, currentDesc),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeIndicator(context, newValue, newDesc),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeIndicator(BuildContext context, double type, String label) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 0 ? constraints.maxWidth : 100.0;
        return Stack(
          children: [
            Container(
              height: 8,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    _frisColor,
                    _neutraalColor,
                    _rijpColor,
                  ],
                ),
              ),
            ),
            Positioned(
              left: (type * width) - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _generateDescription(Smaakprofiel profiel) {
    final mondgevoelDesc = profiel.mondgevoel.dominant;
    final typeDesc = profiel.smaakrijkdom.typeDescription;
    final gehalteDesc = profiel.smaakrijkdom.gehalte > 0.7
        ? 'intens'
        : profiel.smaakrijkdom.gehalte > 0.4
            ? 'gematigd'
            : 'licht';

    // Generate balance description
    final strakFilmendRatio = profiel.mondgevoel.strakFilmendRatio;
    String balanceDesc = '';
    if (strakFilmendRatio >= 0.3 && strakFilmendRatio <= 3.0) {
      balanceDesc = 'Goed gebalanceerd';
    } else if (strakFilmendRatio < 0.3) {
      balanceDesc = 'Romig/filmend';
    } else {
      balanceDesc = 'Strak/zuur';
    }

    return '$gehalteDesc, $typeDesc, $mondgevoelDesc - $balanceDesc';
  }

  /// Calculate new profiel by adding ingredient (simplified weighted average)
  Smaakprofiel _calculateNewProfiel(
    Smaakprofiel current,
    Smaakprofiel ingredient,
  ) {
    // Simplified: assume ingredient has weight 25 (supporting) vs current total weight
    // This is a preview, so we use a simple average approximation
    final currentWeight = 100.0; // Assume current has weight 100
    final ingredientWeight = 25.0; // Supporting ingredient
    final totalWeight = currentWeight + ingredientWeight;

    return Smaakprofiel(
      mondgevoel: Mondgevoel(
        strak: ((current.mondgevoel.strak * currentWeight) +
                (ingredient.mondgevoel.strak * ingredientWeight)) /
            totalWeight,
        filmend: ((current.mondgevoel.filmend * currentWeight) +
                (ingredient.mondgevoel.filmend * ingredientWeight)) /
            totalWeight,
        droog: ((current.mondgevoel.droog * currentWeight) +
                (ingredient.mondgevoel.droog * ingredientWeight)) /
            totalWeight,
      ),
      smaakrijkdom: Smaakrijkdom(
        gehalte: ((current.smaakrijkdom.gehalte * currentWeight) +
                (ingredient.smaakrijkdom.gehalte * ingredientWeight)) /
            totalWeight,
        type: ((current.smaakrijkdom.type * currentWeight) +
                (ingredient.smaakrijkdom.type * ingredientWeight)) /
            totalWeight,
      ),
    );
  }

  // Color definitions
  static const _strakColor = Color(0xFF4A90E2);
  static const _filmendColor = Color(0xFFF5A623);
  static const _droogColor = Color(0xFF8B7355);
  static const _frisColor = Color(0xFF50C878);
  static const _neutraalColor = Color(0xFFD4A574);
  static const _rijpColor = Color(0xFF8B4513);
}
