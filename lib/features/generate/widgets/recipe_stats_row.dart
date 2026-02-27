import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class RecipeStatsRow extends StatelessWidget {
  const RecipeStatsRow({
    super.key,
    this.prepTime,
    this.cookTime,
    this.servings,
    this.difficulty,
  });

  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chips = <Widget>[
      if (prepTime != null && prepTime! > 0)
        _StatChip(
          icon: Icons.restaurant_rounded,
          label: '${prepTime}m prep',
        ),
      if (cookTime != null && cookTime! > 0)
        _StatChip(
          icon: Icons.local_fire_department_rounded,
          label: '${cookTime}m cook',
        ),
      if (servings != null && servings! > 0)
        _StatChip(
          icon: Icons.people_alt_rounded,
          label: '$servings servings',
        ),
      if (difficulty != null && difficulty!.trim().isNotEmpty)
        _StatChip(
          icon: Icons.auto_awesome_rounded,
          label: difficulty!.trim(),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: chips,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

