import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/smaakprofiel.dart';
import '../../../shared/models/balans_analyse.dart';

/// Smaakprofiel Visualization Widget
/// Displays mondgevoel bars and smaakrijkdom slider
/// Based on universele smaakfactoren from boek_compleet.md
class SmaakprofielVisualisatie extends StatelessWidget {
  const SmaakprofielVisualisatie({
    super.key,
    required this.smaakprofiel,
    this.balans,
    this.compact = false,
  });

  final Smaakprofiel smaakprofiel;
  final BalansAnalyse? balans;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactView(context, theme, isDark);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Smaakprofiel',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (balans != null) _buildBalanceChip(context, balans!),
            ],
          ),
          const SizedBox(height: 24),

          // Mondgevoel Section
          Text(
            'MONDGEVOEL',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          _buildMondgevoelBar(
            context,
            'Strak',
            smaakprofiel.mondgevoel.strak,
            _strakColor,
            'Samentrekkend',
          ),
          const SizedBox(height: 10),
          _buildMondgevoelBar(
            context,
            'Filmend',
            smaakprofiel.mondgevoel.filmend,
            _filmendColor,
            'Laat laagje achter',
          ),
          const SizedBox(height: 10),
          _buildMondgevoelBar(
            context,
            'Droog',
            smaakprofiel.mondgevoel.droog,
            _droogColor,
            'Absorbeert vocht',
          ),
          const SizedBox(height: 24),

          // Smaakrijkdom Section
          Text(
            'SMAAKRIJKDOM',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          _buildSmaakgehalteBar(context, smaakprofiel.smaakrijkdom.gehalte),
          const SizedBox(height: 16),
          _buildSmaaktypeSlider(context, smaakprofiel.smaakrijkdom.type),

          // Balance feedback
          if (balans != null && balans!.beschrijving != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: balans!.isBalanced
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    balans!.isBalanced ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                    color: balans!.isBalanced
                        ? AppColors.primary
                        : AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      balans!.beschrijving!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context, ThemeData theme, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDot(_strakColor, smaakprofiel.mondgevoel.strak, 'Strak'),
        const SizedBox(width: 6),
        _buildCompactDot(
            _filmendColor, smaakprofiel.mondgevoel.filmend, 'Filmend'),
        const SizedBox(width: 6),
        _buildCompactDot(_droogColor, smaakprofiel.mondgevoel.droog, 'Droog'),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 20,
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
        const SizedBox(width: 8),
        _buildCompactTypeIndicator(smaakprofiel.smaakrijkdom.type),
      ],
    );
  }

  Widget _buildCompactDot(Color color, double value, String label) {
    final size = 8 + (value * 12); // 8-20 based on value
    return Tooltip(
      message: '$label: ${(value * 100).round()}%',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3 + (value * 0.7)),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTypeIndicator(double type) {
    // Show position on fris-rijp spectrum
    return Tooltip(
      message: type < 0.3
          ? 'Fris'
          : type < 0.7
              ? 'Neutraal'
              : 'Rijp',
      child: Container(
        width: 40,
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: LinearGradient(
            colors: [
              _frisColor,
              _neutraalColor,
              _rijpColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: type * 40 - 2,
              child: Container(
                width: 4,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMondgevoelBar(
    BuildContext context,
    String label,
    double value,
    Color color,
    String description,
  ) {
    final theme = Theme.of(context);
    final percentage = (value * 100).round();
    final isBalanced = balans?.isBalanced ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (value > 0.5 && isBalanced) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSmaakgehalteBar(BuildContext context, double gehalte) {
    final theme = Theme.of(context);
    final percentage = (gehalte * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gehalte',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: gehalte.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(_gehalteColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSmaaktypeSlider(BuildContext context, double type) {
    final theme = Theme.of(context);
    final typeDesc = type < 0.3
        ? 'Fris'
        : type < 0.7
            ? 'Neutraal'
            : 'Rijp';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Type',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              typeDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final sliderWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;
            return Stack(
              children: [
                // Background gradient
                Container(
                  height: 10,
                  width: sliderWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [
                        _frisColor,
                        _neutraalColor,
                        _rijpColor,
                      ],
                    ),
                  ),
                ),
                // Indicator
                Positioned(
                  left: (type * sliderWidth) - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fris',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            Text(
              'Rijp',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceChip(BuildContext context, BalansAnalyse balans) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: balans.isBalanced
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            balans.isBalanced ? Icons.check_circle : Icons.info_outline,
            size: 14,
            color: balans.isBalanced ? AppColors.primary : AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            balans.isBalanced ? 'Gebalanceerd' : 'Onbalans',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: balans.isBalanced ? AppColors.primary : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  // Color definitions
  static const _strakColor = Color(0xFF4A90E2); // Blue for astringent
  static const _filmendColor = Color(0xFFF5A623); // Orange/gold for coating
  static const _droogColor = Color(0xFF8B7355); // Brown for dry
  static const _gehalteColor = Color(0xFF7B68EE); // Purple for intensity
  static const _frisColor = Color(0xFF50C878); // Green for fresh
  static const _neutraalColor = Color(0xFFD4A574); // Gold for neutral
  static const _rijpColor = Color(0xFF8B4513); // Brown for ripe
}
