import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_config.dart';
import '../../../services/openai_service.dart';
import '../../../services/image_storage_service.dart';
import '../../../services/preferences_service.dart';
import '../../../shared/models/recipe.dart';
import '../../../shared/models/recipe_preferences.dart';

class GenerateState {
  const GenerateState({
    this.ingredients = const [],
    this.preferences = const RecipePreferences(),
    this.isLoading = false,
    this.imageLoading = false,
    this.loadingMessage,
    this.imageError,
    this.error,
    this.generatedRecipe,
  });

  final List<String> ingredients;
  final RecipePreferences preferences;
  final bool isLoading;
  final bool imageLoading;
  final String? loadingMessage;
  final String? imageError;
  final String? error;
  final Recipe? generatedRecipe;

  GenerateState copyWith({
    List<String>? ingredients,
    RecipePreferences? preferences,
    bool? isLoading,
    bool? imageLoading,
    String? loadingMessage,
    String? imageError,
    String? error,
    Recipe? generatedRecipe,
  }) {
    return GenerateState(
      ingredients: ingredients ?? this.ingredients,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      imageLoading: imageLoading ?? this.imageLoading,
      loadingMessage: loadingMessage,
      imageError: imageError,
      error: error,
      generatedRecipe: generatedRecipe ?? this.generatedRecipe,
    );
  }
}

final generateProvider =
    StateNotifierProvider<GenerateNotifier, GenerateState>((ref) {
  return GenerateNotifier();
});

class GenerateNotifier extends StateNotifier<GenerateState> {
  GenerateNotifier() : super(const GenerateState()) {
    _loadUserPreferences();
  }

  final _openAI = OpenAIService.instance;
  final _preferencesService = PreferencesService.instance;
  final _loadingMessages = const [
    'Chopping ingredients...',
    'Simmering ideas...',
    'Plating your recipe...',
    'Mixing flavors...',
    'Preheating inspiration...',
  ];

  Future<void> _loadUserPreferences() async {
    try {
      final userPrefs = await _preferencesService.getPreferences();
      // Apply user preferences to recipe preferences
      state = state.copyWith(
        preferences: RecipePreferences(
          servings: userPrefs.defaultServings,
          dietaryRestrictions: userPrefs.dietaryPreferences,
          cuisine: userPrefs.preferredCuisines.isNotEmpty
              ? userPrefs.preferredCuisines.first
              : null,
        ),
      );
    } catch (e) {
      // Keep defaults on error
    }
  }

  void addIngredient(String ingredient) {
    final value = ingredient.trim();
    if (value.isEmpty) return;
    if (state.ingredients.contains(value)) return;
    state = state.copyWith(
      ingredients: [...state.ingredients, value],
      error: null,
    );
  }

  void removeIngredient(String ingredient) {
    state = state.copyWith(
      ingredients: state.ingredients.where((e) => e != ingredient).toList(),
      error: null,
    );
  }

  void updatePreferences(RecipePreferences preferences) {
    state = state.copyWith(preferences: preferences, error: null);
  }

  Future<void> generateRecipe() async {
    if (state.ingredients.isEmpty) {
      state = state.copyWith(error: 'Add at least one ingredient');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      loadingMessage: _loadingMessages[Random().nextInt(_loadingMessages.length)],
      imageLoading: false,
      imageError: null,
    );

    try {
      print('🔄 [GenerateProvider] Starting recipe generation...');
      final recipe = await _openAI.generateRecipe(
        ingredients: state.ingredients,
        preferences: state.preferences,
      );
      print('✅ [GenerateProvider] Recipe generated: ${recipe.title}');
      
      state = state.copyWith(
        generatedRecipe: recipe,
        isLoading: false,
        loadingMessage: null,
      );
      print('✅ [GenerateProvider] State updated with recipe');

      // Always start image generation in background (don't await)
      // User can see recipe immediately while image loads
      // Image generation will continue on the recipe page
      print('🖼️ [GenerateProvider] Starting image generation in background...');
      _generateImage(recipe);
    } catch (e) {
      print('❌ [GenerateProvider] Error: $e');
      state = state.copyWith(
        isLoading: false,
        loadingMessage: null,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setInitialIngredients(List<String> ingredients) {
    state = state.copyWith(
      ingredients: ingredients,
      error: null,
    );
  }

  void clearAll() {
    state = const GenerateState();
  }

  /// Manually trigger image generation (opt-in for free tier)
  /// Can also be called to continue image generation if recipe exists
  Future<void> generateImage() async {
    final recipe = state.generatedRecipe;
    if (recipe == null) return;
    
    // Don't start if already loading
    if (state.imageLoading) return;
    
    // Don't start if image already exists
    if (recipe.imageUrl != null) return;
    
    await _generateImage(recipe);
  }

  Future<void> _generateImage(Recipe recipe) async {
    state = state.copyWith(imageLoading: true, imageError: null);
    try {
      // Generate image using Replicate
      final generatedImageUrl = await _openAI.generateRecipeImage(
        recipe: recipe,
      );
      
      if (generatedImageUrl == null) {
        state = state.copyWith(
          imageLoading: false,
          imageError: 'Could not generate image',
        );
        return;
      }

      // Check if image is already in Supabase Storage
      final imageStorage = ImageStorageService.instance;
      if (imageStorage.isSupabaseStorageUrl(generatedImageUrl)) {
        // Already stored in Supabase, use it directly
        state = state.copyWith(
          generatedRecipe: state.generatedRecipe?.copyWith(imageUrl: generatedImageUrl),
          imageLoading: false,
        );
        return;
      }

      // Upload image to Supabase Storage for permanent storage
      // Use recipe ID or generate a temporary ID for storage path
      final recipeId = recipe.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final storedImageUrl = await imageStorage.uploadImageFromUrl(
        imageUrl: generatedImageUrl,
        recipeId: recipeId,
      );

      // Use stored URL if upload succeeded, otherwise fall back to original URL
      final finalImageUrl = storedImageUrl ?? generatedImageUrl;
      
      state = state.copyWith(
        generatedRecipe: state.generatedRecipe?.copyWith(imageUrl: finalImageUrl),
        imageLoading: false,
      );
    } catch (e) {
      print('Image generation/storage error: $e');
      state = state.copyWith(
        imageLoading: false,
        imageError: 'Could not generate image',
      );
    }
  }
}
