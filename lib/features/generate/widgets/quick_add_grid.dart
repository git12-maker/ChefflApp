import 'package:flutter/material.dart';

class QuickAddGrid extends StatelessWidget {
  const QuickAddGrid({
    super.key,
    required this.onAdd,
    this.items = const [
      'chicken',
      'rice',
      'tomato',
      'onion',
      'garlic',
      'pasta',
      'egg',
      'cheese',
    ],
  });

  final void Function(String) onAdd;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => ActionChip(
              label: Text(item),
              onPressed: () => onAdd(item),
            ),
          )
          .toList(),
    );
  }
}
