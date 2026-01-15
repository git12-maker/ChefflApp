import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IngredientInput extends StatefulWidget {
  const IngredientInput({
    super.key,
    required this.onAdd,
    this.hintText = 'Add ingredient',
    this.showCameraButton = true,
  });

  final void Function(String) onAdd;
  final String hintText;
  final bool showCameraButton;

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

  void _openCamera() {
    // Navigate to scan screen - it will add ingredients to existing list
    context.push('/scan');
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
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showCameraButton) ...[
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: _openCamera,
                tooltip: 'Scan ingredients',
                iconSize: 22,
                padding: const EdgeInsets.all(8),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _submit,
              tooltip: 'Add ingredient',
            ),
          ],
        ),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      autofocus: false, // Don't auto-focus on first build, but keep focus after submit
    );
  }
}
