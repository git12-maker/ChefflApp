import 'package:flutter/material.dart';
import '../../../shared/models/recipe.dart';
import '../../../core/constants/colors.dart';

class IngredientChecklist extends StatefulWidget {
  const IngredientChecklist({super.key, required this.ingredients});

  final List<RecipeIngredient> ingredients;

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  final Set<int> _checked = {};
  List<RecipeIngredient>? _previousIngredients;

  @override
  void didUpdateWidget(IngredientChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if ingredients actually changed (e.g., after conversion)
    final ingredientsChanged = _previousIngredients == null ||
        oldWidget.ingredients.length != widget.ingredients.length ||
        oldWidget.ingredients.asMap().entries.any((entry) {
          final index = entry.key;
          final oldIng = entry.value;
          if (index >= widget.ingredients.length) return true;
          final newIng = widget.ingredients[index];
          return oldIng.name != newIng.name || oldIng.amount != newIng.amount;
        });
    
    if (ingredientsChanged) {
      // Ingredients changed - reset checked items
      _checked.clear();
      _previousIngredients = List<RecipeIngredient>.from(widget.ingredients);
    }
  }

  @override
  void initState() {
    super.initState();
    _previousIngredients = List<RecipeIngredient>.from(widget.ingredients);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show summary if there are auto-added ingredients
        if (widget.ingredients.any((i) => !i.isUserProvided)) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some ingredients were automatically added from instructions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ...widget.ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          final checked = _checked.contains(index);
          final isUserProvided = ingredient.isUserProvided;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isUserProvided 
                  ? Colors.transparent
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: isUserProvided 
                  ? null
                  : Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
            ),
            child: CheckboxListTile(
              value: checked,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _checked.add(index);
                  } else {
                    _checked.remove(index);
                  }
                });
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ingredient.amount} • ${ingredient.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isUserProvided ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!isUserProvided) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Auto',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ],
    );
  }
}
