import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/ingredient.dart';

/// Visual indicator for flavor balance analysis
/// Shows the gustatory profile of selected ingredients
class FlavorBalanceIndicator extends StatelessWidget {
  const FlavorBalanceIndicator({
    super.key,
    required this.flavorProfile,
    this.compact = false,
  });

  final FlavorProfile flavorProfile;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (compact) {
      return _buildCompactIndicator(context);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
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
                Icons.balance_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Flavor Balance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildBalanceChip(context),
            ],
          ),
          const SizedBox(height: 16),
          _buildFlavorBar(context, 'Sweet', flavorProfile.sweetness, _sweetColor),
          const SizedBox(height: 8),
          _buildFlavorBar(context, 'Salty', flavorProfile.saltiness, _saltyColor),
          const SizedBox(height: 8),
          _buildFlavorBar(context, 'Sour', flavorProfile.sourness, _sourColor),
          const SizedBox(height: 8),
          _buildFlavorBar(context, 'Bitter', flavorProfile.bitterness, _bitterColor),
          const SizedBox(height: 8),
          _buildFlavorBar(context, 'Umami', flavorProfile.umami, _umamiColor),
        ],
      ),
    );
  }

  Widget _buildCompactIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDot(_sweetColor, flavorProfile.sweetness, 'Sweet'),
        const SizedBox(width: 4),
        _buildCompactDot(_saltyColor, flavorProfile.saltiness, 'Salt'),
        const SizedBox(width: 4),
        _buildCompactDot(_sourColor, flavorProfile.sourness, 'Sour'),
        const SizedBox(width: 4),
        _buildCompactDot(_bitterColor, flavorProfile.bitterness, 'Bitter'),
        const SizedBox(width: 4),
        _buildCompactDot(_umamiColor, flavorProfile.umami, 'Umami'),
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
            color: color,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFlavorBar(BuildContext context, String label, double value, Color color) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.7),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '${(value * 100).round()}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceChip(BuildContext context) {
    final theme = Theme.of(context);
    final isBalanced = flavorProfile.isBalanced;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isBalanced 
            ? Colors.green.withOpacity(0.15)
            : Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBalanced ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBalanced ? Icons.check_circle_outline : Icons.info_outline,
            size: 14,
            color: isBalanced ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isBalanced ? 'Balanced' : 'Needs balance',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isBalanced ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Flavor colors based on culinary conventions
  static const _sweetColor = Color(0xFFE91E63); // Pink
  static const _saltyColor = Color(0xFF2196F3); // Blue
  static const _sourColor = Color(0xFFFFEB3B); // Yellow
  static const _bitterColor = Color(0xFF795548); // Brown
  static const _umamiColor = Color(0xFF9C27B0); // Purple - the "fifth taste"
}
