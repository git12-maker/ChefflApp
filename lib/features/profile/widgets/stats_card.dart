import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.totalRecipes,
    required this.favoritesCount,
    required this.recipesThisMonth,
  });

  final int totalRecipes;
  final int favoritesCount;
  final int recipesThisMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.book_outlined,
            label: 'Saved',
            value: totalRecipes.toString(),
            color: AppColors.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          _StatItem(
            icon: Icons.favorite_outline,
            label: 'Favorites',
            value: favoritesCount.toString(),
            color: AppColors.accent,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          _StatItem(
            icon: Icons.auto_awesome_outlined,
            label: 'This Month',
            value: recipesThisMonth.toString(),
            color: AppColors.info,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
