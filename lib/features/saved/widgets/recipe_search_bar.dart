import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class RecipeSearchBar extends StatefulWidget {
  const RecipeSearchBar({
    super.key,
    required this.onChanged,
  });

  final ValueChanged<String> onChanged;

  @override
  State<RecipeSearchBar> createState() => _RecipeSearchBarState();
}

class _RecipeSearchBarState extends State<RecipeSearchBar> {
  Timer? _debounceTimer;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Set new timer for debouncing (300ms delay)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: AppBorderRadius.largeAll,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: theme.textTheme.bodyMedium,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
