import 'package:flutter/material.dart';
import '../../../shared/models/recipe.dart';

class IngredientChecklist extends StatefulWidget {
  const IngredientChecklist({super.key, required this.ingredients});

  final List<RecipeIngredient> ingredients;

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;
        final checked = _checked.contains(index);
        return CheckboxListTile(
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
          title: Text('${ingredient.amount} • ${ingredient.name}'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}
