import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class AddIngredientInput extends StatefulWidget {
  const AddIngredientInput({
    super.key,
    required this.onAdd,
  });

  final ValueChanged<String> onAdd;

  @override
  State<AddIngredientInput> createState() => _AddIngredientInputState();
}

class _AddIngredientInputState extends State<AddIngredientInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) {
      widget.onAdd(value);
      _controller.clear();
      _focusNode.unfocus();
    }
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Add ingredient manually...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.add_circle_outline_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  onPressed: _handleSubmit,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleSubmit(),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
