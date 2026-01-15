import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.isFavoritesOnly,
    required this.onToggle,
  });

  final bool isFavoritesOnly;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
          label: 'All',
          selected: !isFavoritesOnly,
          onTap: () => onToggle(false),
        ),
        const SizedBox(width: 12),
        _Tab(
          label: 'Favorites',
          selected: isFavoritesOnly,
          onTap: () => onToggle(true),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.xlargeAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primaryDark.withOpacity(0.2),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.accent.withOpacity(0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: AppBorderRadius.xlargeAll,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withOpacity(isDark ? 0.4 : 0.3)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
