import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class CuisineChip extends StatelessWidget {
  const CuisineChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.primary.withOpacity(0.25),
                      AppColors.primaryDark.withOpacity(0.15),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.accent.withOpacity(0.08),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppBorderRadius.xlargeAll,
            border: Border.all(
              color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
