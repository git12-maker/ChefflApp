import 'package:flutter/material.dart';
import '../../../shared/models/recipe_preferences.dart';

class PreferencesPanel extends StatelessWidget {
  const PreferencesPanel({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final RecipePreferences preferences;
  final void Function(RecipePreferences) onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Preferences'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _servingsSelector(context),
              const SizedBox(height: 12),
              _difficultyDropdown(context),
              const SizedBox(height: 12),
              _cuisineDropdown(context),
              const SizedBox(height: 12),
              _dietaryChips(context),
              const SizedBox(height: 12),
              _maxTimeSlider(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _servingsSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Servings'),
        DropdownButton<int>(
          value: preferences.servings,
          onChanged: (value) {
            if (value != null) {
              onChanged(preferences.copyWith(servings: value));
            }
          },
          items: List.generate(8, (i) => i + 1)
              .map(
                (s) => DropdownMenuItem<int>(
                  value: s,
                  child: Text('$s'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _difficultyDropdown(BuildContext context) {
    const difficulties = ['easy', 'medium', 'hard'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Difficulty'),
        DropdownButton<String?>(
          value: preferences.difficulty,
          hint: const Text('Any'),
          onChanged: (value) {
            onChanged(preferences.copyWith(difficulty: value));
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Any'),
            ),
            ...difficulties.map(
              (d) => DropdownMenuItem<String?>(
                value: d,
                child: Text(d),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cuisineDropdown(BuildContext context) {
    const cuisines = [
      'Italian',
      'Asian',
      'Mexican',
      'Mediterranean',
      'American',
      'Indian',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Cuisine'),
        DropdownButton<String?>(
          value: preferences.cuisine,
          hint: const Text('Any'),
          onChanged: (value) => onChanged(preferences.copyWith(cuisine: value)),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Any'),
            ),
            ...cuisines.map(
              (c) => DropdownMenuItem<String?>(
                value: c,
                child: Text(c),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dietaryChips(BuildContext context) {
    const tags = [
      'vegetarian',
      'vegan',
      'gluten-free',
      'dairy-free',
      'keto',
      'paleo',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dietary tags'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => FilterChip(
                  label: Text(tag),
                  selected: preferences.dietaryRestrictions.contains(tag),
                  onSelected: (selected) {
                    final current = List<String>.from(
                        preferences.dietaryRestrictions);
                    if (selected) {
                      current.add(tag);
                    } else {
                      current.remove(tag);
                    }
                    onChanged(preferences.copyWith(
                        dietaryRestrictions: current));
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _maxTimeSlider(BuildContext context) {
    final value = preferences.maxTimeMinutes?.toDouble() ?? 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Max cooking time'),
            Text('${value.round()} min'),
          ],
        ),
        Slider(
          value: value,
          min: 10,
          max: 120,
          divisions: 11,
          label: '${value.round()} min',
          onChanged: (newValue) {
            onChanged(
              preferences.copyWith(maxTimeMinutes: newValue.round()),
            );
          },
        ),
      ],
    );
  }
}
