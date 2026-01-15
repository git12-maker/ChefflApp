import 'package:flutter/material.dart';

class RecipeStatsRow extends StatelessWidget {
  const RecipeStatsRow({
    super.key,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
  });

  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final String? difficulty;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (prepTime != null) _Stat(icon: Icons.timer_outlined, label: 'Prep', value: '${prepTime!}m'),
      if (cookTime != null) _Stat(icon: Icons.soup_kitchen_outlined, label: 'Cook', value: '${cookTime!}m'),
      if (servings != null) _Stat(icon: Icons.people_alt_outlined, label: 'Serves', value: '$servings'),
      if (difficulty != null) _Stat(icon: Icons.terrain_outlined, label: 'Level', value: difficulty!),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((e) => _StatTile(stat: e)).toList(),
    );
  }
}

class _Stat {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.label, style: theme.textTheme.labelMedium),
              Text(
                stat.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
