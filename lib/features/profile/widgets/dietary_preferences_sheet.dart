import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class DietaryPreferencesSheet extends StatefulWidget {
  const DietaryPreferencesSheet({
    super.key,
    required this.selectedPreferences,
    required this.onSave,
  });

  final List<String> selectedPreferences;
  final ValueChanged<List<String>> onSave;

  @override
  State<DietaryPreferencesSheet> createState() =>
      _DietaryPreferencesSheetState();
}

class _DietaryPreferencesSheetState extends State<DietaryPreferencesSheet> {
  late List<String> _selected;

  static const List<String> _allPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'Low-Fat',
    'Sugar-Free',
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedPreferences);
  }

  void _togglePreference(String preference) {
    setState(() {
      if (_selected.contains(preference)) {
        _selected.remove(preference);
      } else {
        _selected.add(preference);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dietary Preferences',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onSave(_selected),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          // Preferences list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _allPreferences.length,
              itemBuilder: (context, index) {
                final preference = _allPreferences[index];
                final isSelected = _selected.contains(preference);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _togglePreference(preference),
                  title: Text(preference),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
