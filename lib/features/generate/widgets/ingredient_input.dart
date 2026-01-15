import 'package:flutter/material.dart';

class IngredientInput extends StatefulWidget {
  const IngredientInput({
    super.key,
    required this.onAdd,
    this.hintText = 'Add ingredient',
  });

  final void Function(String) onAdd;
  final String hintText;

  @override
  State<IngredientInput> createState() => _IngredientInputState();
}

class _IngredientInputState extends State<IngredientInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onAdd(value);
    _controller.clear();
    // Keep focus on the text field for quick entry
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          onPressed: _submit,
        ),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      autofocus: false, // Don't auto-focus on first build, but keep focus after submit
    );
  }
}
