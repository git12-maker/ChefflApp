import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/ingredients_service.dart';

class GenerateSimpleState {
  const GenerateSimpleState({
    this.selected = const [],
    this.isGenerating = false,
  });

  final List<SimpleIngredient> selected;
  final bool isGenerating;

  GenerateSimpleState copyWith({
    List<SimpleIngredient>? selected,
    bool? isGenerating,
  }) {
    return GenerateSimpleState(
      selected: selected ?? this.selected,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class GenerateSimpleNotifier extends StateNotifier<GenerateSimpleState> {
  GenerateSimpleNotifier() : super(const GenerateSimpleState());

  void addIngredient(SimpleIngredient ing) {
    if (state.selected.any((s) => s.name == ing.name)) return;
    // Last added first - prepend new ingredient
    state = state.copyWith(selected: [ing, ...state.selected]);
  }

  void removeIngredient(String name) {
    state = state.copyWith(
      selected: state.selected.where((s) => s.name != name).toList(),
    );
  }

  void setGenerating(bool v) {
    state = state.copyWith(isGenerating: v);
  }

  void clear() {
    state = const GenerateSimpleState();
  }
}

final generateSimpleProvider =
    StateNotifierProvider<GenerateSimpleNotifier, GenerateSimpleState>(
        (ref) => GenerateSimpleNotifier());
