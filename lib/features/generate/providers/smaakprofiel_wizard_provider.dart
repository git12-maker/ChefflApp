import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/smaakprofiel.dart';
import '../../../shared/models/balans_analyse.dart';
import '../../../services/smaakprofiel_service.dart';
import '../../../shared/models/ingredient.dart';

/// Wizard step enum
enum WizardStep {
  start, // Choose main ingredient category
  chooseMainIngredient, // Choose specific main ingredient
  chooseCookingMethod, // Choose how to prepare
  firstProfile, // Show first flavor profile
  addIngredients, // Add more ingredients
  previewIngredient, // Preview what ingredient adds
  updatedDish, // Show updated dish
  finalResult, // Final result screen
}

/// State for the Smaakprofiel Wizard
class SmaakprofielWizardState {
  final WizardStep currentStep;
  final String? selectedCategory; // Vis, Gevogelte, Vlees, Groente, Peulvruchten
  final Ingredient? mainIngredient;
  final String? cookingMethod;
  final List<Ingredient> additionalIngredients;
  final Ingredient? previewIngredient; // Ingredient being previewed
  final Smaakprofiel? currentProfile;
  final Smaakprofiel? previousProfile; // Track previous for feedback
  final BalansAnalyse? balanceAnalysis;
  final bool isLoading;
  final int shuffleSeed; // For shuffling suggestions

  SmaakprofielWizardState({
    this.currentStep = WizardStep.start,
    this.selectedCategory,
    this.mainIngredient,
    this.cookingMethod,
    this.additionalIngredients = const [],
    this.previewIngredient,
    this.currentProfile,
    this.previousProfile,
    this.balanceAnalysis,
    this.isLoading = false,
    this.shuffleSeed = 0,
  });

  SmaakprofielWizardState copyWith({
    WizardStep? currentStep,
    String? selectedCategory,
    Ingredient? mainIngredient,
    String? cookingMethod,
    List<Ingredient>? additionalIngredients,
    Ingredient? previewIngredient,
    Smaakprofiel? currentProfile,
    Smaakprofiel? previousProfile,
    BalansAnalyse? balanceAnalysis,
    bool? isLoading,
    int? shuffleSeed,
  }) {
    return SmaakprofielWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      mainIngredient: mainIngredient ?? this.mainIngredient,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      additionalIngredients: additionalIngredients ?? this.additionalIngredients,
      previewIngredient: previewIngredient,
      currentProfile: currentProfile ?? this.currentProfile,
      previousProfile: previousProfile ?? this.previousProfile,
      balanceAnalysis: balanceAnalysis ?? this.balanceAnalysis,
      isLoading: isLoading ?? this.isLoading,
      shuffleSeed: shuffleSeed ?? this.shuffleSeed,
    );
  }

  /// Get all selected ingredients (main + additional)
  List<Ingredient> get allIngredients {
    final list = <Ingredient>[];
    if (mainIngredient != null) list.add(mainIngredient!);
    list.addAll(additionalIngredients);
    return list;
  }

  /// Check if we can go back
  bool canGoBack() {
    return currentStep != WizardStep.start;
  }

  /// Check if we can go forward
  bool canGoForward() {
    switch (currentStep) {
      case WizardStep.start:
        return selectedCategory != null;
      case WizardStep.chooseMainIngredient:
        return mainIngredient != null;
      case WizardStep.chooseCookingMethod:
        return cookingMethod != null;
      case WizardStep.firstProfile:
      case WizardStep.addIngredients:
      case WizardStep.previewIngredient:
      case WizardStep.updatedDish:
      case WizardStep.finalResult:
        return true; // Can always proceed from these
    }
  }
}

/// Provider for Smaakprofiel Wizard state
final smaakprofielWizardProvider =
    StateNotifierProvider<SmaakprofielWizardNotifier, SmaakprofielWizardState>((ref) {
  return SmaakprofielWizardNotifier();
});

class SmaakprofielWizardNotifier extends StateNotifier<SmaakprofielWizardState> {
  SmaakprofielWizardNotifier() : super(SmaakprofielWizardState());

  final _smaakprofielService = SmaakprofielService.instance;

  /// Select category and move to next step
  void selectCategory(String category) {
    state = state.copyWith(
      selectedCategory: category,
      currentStep: WizardStep.chooseMainIngredient,
    );
  }

  /// Select main ingredient and move to next step
  void selectMainIngredient(Ingredient ingredient) {
    state = state.copyWith(
      mainIngredient: ingredient,
      currentStep: WizardStep.chooseCookingMethod,
    );
  }

  /// Select cooking method and calculate first profile
  Future<void> selectCookingMethod(String method) async {
    state = state.copyWith(
      cookingMethod: method,
      isLoading: true,
    );

    try {
      await _calculateProfile();
      state = state.copyWith(
        currentStep: WizardStep.firstProfile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Add additional ingredient
  Future<void> addIngredient(Ingredient ingredient) async {
    // Save previous profile for feedback
    final previousProfile = state.currentProfile;
    
    final updated = [...state.additionalIngredients, ingredient];
    state = state.copyWith(
      additionalIngredients: updated,
      previewIngredient: null,
      previousProfile: previousProfile, // Track previous for feedback
    );
    
    // Recalculate profile - THIS IS THE BUG FIX
    await _calculateProfile();
    
    state = state.copyWith(currentStep: WizardStep.updatedDish);
  }

  /// Preview ingredient effect
  void previewIngredient(Ingredient ingredient) {
    state = state.copyWith(
      previewIngredient: ingredient,
      currentStep: WizardStep.previewIngredient,
    );
  }

  /// Go to add ingredients screen
  void goToAddIngredients() {
    state = state.copyWith(
      currentStep: WizardStep.addIngredients,
      previewIngredient: null,
    );
  }

  /// Finish dish and show final result
  Future<void> finishDish() async {
    await _calculateProfile();
    state = state.copyWith(currentStep: WizardStep.finalResult);
  }

  /// Navigate back
  void goBack() {
    if (!state.canGoBack()) return;

    switch (state.currentStep) {
      case WizardStep.chooseMainIngredient:
        state = state.copyWith(
          currentStep: WizardStep.start,
          selectedCategory: null,
        );
        break;
      case WizardStep.chooseCookingMethod:
        state = state.copyWith(
          currentStep: WizardStep.chooseMainIngredient,
          mainIngredient: null,
        );
        break;
      case WizardStep.firstProfile:
        state = state.copyWith(
          currentStep: WizardStep.chooseCookingMethod,
          cookingMethod: null,
        );
        break;
      case WizardStep.addIngredients:
        state = state.copyWith(currentStep: WizardStep.firstProfile);
        break;
      case WizardStep.previewIngredient:
        state = state.copyWith(
          currentStep: WizardStep.addIngredients,
          previewIngredient: null,
        );
        break;
      case WizardStep.updatedDish:
        state = state.copyWith(currentStep: WizardStep.firstProfile);
        break;
      case WizardStep.finalResult:
        state = state.copyWith(currentStep: WizardStep.updatedDish);
        break;
      case WizardStep.start:
        break;
    }
  }

  /// Calculate current profile
  Future<void> _calculateProfile() async {
    if (state.allIngredients.isEmpty) {
      state = state.copyWith(
        currentProfile: null,
        balanceAnalysis: null,
      );
      return;
    }

    try {
      // Get smaakprofielen for all ingredients with cooking methods
      final cookingMethods = <String, String>{};
      if (state.mainIngredient != null && state.cookingMethod != null) {
        cookingMethods[state.mainIngredient!.name] = state.cookingMethod!;
      }

      final ingredientProfiles = await _smaakprofielService.getIngredientSmaakprofielen(
        state.allIngredients,
        cookingMethods.isNotEmpty ? cookingMethods : null,
      );

      // Calculate combined profile
      final combined = _smaakprofielService.berekenGecombineerdProfiel(ingredientProfiles);

      // Analyze balance
      final balance = BalansAnalyzer.analyseer(combined);

      state = state.copyWith(
        currentProfile: combined,
        balanceAnalysis: balance,
      );
    } catch (e) {
      // Error calculating - keep existing profile
    }
  }

  /// Shuffle suggestions
  void shuffleSuggestions() {
    state = state.copyWith(shuffleSeed: state.shuffleSeed + 1);
  }

  /// Reset wizard
  void reset() {
    state = SmaakprofielWizardState();
  }
}
