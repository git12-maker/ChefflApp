import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.currentTheme,
    required this.onChanged,
  });

  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeOption(
              label: 'Light',
              icon: Icons.light_mode_outlined,
              isSelected: currentTheme == ThemeMode.light,
              onTap: () => onChanged(ThemeMode.light),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          Expanded(
            child: _ThemeOption(
              label: 'Dark',
              icon: Icons.dark_mode_outlined,
              isSelected: currentTheme == ThemeMode.dark,
              onTap: () => onChanged(ThemeMode.dark),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          Expanded(
            child: _ThemeOption(
              label: 'System',
              icon: Icons.brightness_auto_outlined,
              isSelected: currentTheme == ThemeMode.system,
              onTap: () => onChanged(ThemeMode.system),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
