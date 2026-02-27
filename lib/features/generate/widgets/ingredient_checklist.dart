import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/recipe.dart';

class IngredientChecklist extends StatefulWidget {
  const IngredientChecklist({
    super.key,
    required this.ingredients,
  });

  final List<RecipeIngredient> ingredients;

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  final Set<int> _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: widget.ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;
        final isChecked = _checked.contains(index);
        final hasImage = ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: InkWell(
            onTap: () => setState(() {
              if (isChecked) {
                _checked.remove(index);
              } else {
                _checked.add(index);
              }
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _checked.add(index);
                          } else {
                            _checked.remove(index);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                      checkColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: ingredient.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 48,
                              height: 48,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => _placeholder(theme),
                          ),
                        )
                      : _placeholder(theme),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ingredient.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                            color: isChecked
                                ? theme.colorScheme.onSurface.withOpacity(0.55)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ingredient.amount,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.restaurant_rounded,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 24,
        ),
      );
}

