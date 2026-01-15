import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class IngredientChip extends StatelessWidget {
  const IngredientChip({
    super.key,
    required this.label,
    required this.onRemoved,
  });

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIconColor: AppColors.error,
      onDeleted: onRemoved,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
