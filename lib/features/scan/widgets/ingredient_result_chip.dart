import 'package:flutter/material.dart';
import '../../../shared/models/recognized_ingredient.dart';
import '../../../core/constants/colors.dart';

class IngredientResultChip extends StatelessWidget {
  const IngredientResultChip({
    super.key,
    required this.ingredient,
    required this.isSelected,
    required this.onTap,
  });

  final RecognizedIngredient ingredient;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(RecognizedIngredient.getCategoryColor(ingredient.category));
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withOpacity(isDark ? 0.3 : 0.2)
                : (isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? categoryColor.withOpacity(0.8)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ingredient.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? categoryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: categoryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
