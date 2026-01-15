import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/camera_service.dart';
import '../../../services/openai_service.dart';
import '../../../shared/models/recognized_ingredient.dart';

class ScanState {
  const ScanState({
    this.selectedImage,
    this.isAnalyzing = false,
    this.recognizedIngredients = const [],
    this.selectedIngredients = const [],
    this.manualIngredients = const [],
    this.error,
    this.analyzingMessage,
  });

  final File? selectedImage;
  final bool isAnalyzing;
  final List<RecognizedIngredient> recognizedIngredients;
  final List<String> selectedIngredients; // Selected ingredient names
  final List<String> manualIngredients; // Manually added ingredients
  final String? error;
  final String? analyzingMessage;

  ScanState copyWith({
    File? selectedImage,
    bool? isAnalyzing,
    List<RecognizedIngredient>? recognizedIngredients,
    List<String>? selectedIngredients,
    List<String>? manualIngredients,
    String? error,
    String? analyzingMessage,
  }) {
    return ScanState(
      selectedImage: selectedImage ?? this.selectedImage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      recognizedIngredients: recognizedIngredients ?? this.recognizedIngredients,
      selectedIngredients: selectedIngredients ?? this.selectedIngredients,
      manualIngredients: manualIngredients ?? this.manualIngredients,
      error: error,
      analyzingMessage: analyzingMessage ?? this.analyzingMessage,
    );
  }

  List<String> get allSelectedIngredients {
    return [...selectedIngredients, ...manualIngredients];
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier() : super(const ScanState());

  final _cameraService = CameraService.instance;
  final _openAIService = OpenAIService.instance;
  
  /// Initialize permissions check when screen opens
  /// Note: On iOS, we don't request permission here - we let image_picker
  /// handle it natively when the user taps "Take Photo" to ensure proper
  /// iOS permission registration
  Future<void> initializePermissions() async {
    // Just check status, don't request yet
    // The actual request happens when user taps "Take Photo"
    if (Platform.isIOS) {
      try {
        final status = await Permission.camera.status;
        print('📷 [ScanNotifier] Camera permission status: $status');
      } catch (e) {
        print('📷 [ScanNotifier] Error checking permission: $e');
      }
    }
  }

  final _analyzingMessages = [
    'Analyzing ingredients...',
    'Identifying food items...',
    'Detecting vegetables and proteins...',
    'Almost done...',
  ];

  Future<void> takePhoto() async {
    try {
      state = state.copyWith(error: null);
      final image = await _cameraService.takePhoto();
      if (image != null) {
        state = state.copyWith(
          selectedImage: image,
          recognizedIngredients: [],
          selectedIngredients: [],
          manualIngredients: [],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pickFromGallery() async {
    try {
      state = state.copyWith(error: null);
      final image = await _cameraService.pickFromGallery();
      if (image != null) {
        state = state.copyWith(
          selectedImage: image,
          recognizedIngredients: [],
          selectedIngredients: [],
          manualIngredients: [],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> analyzeImage() async {
    if (state.selectedImage == null) {
      state = state.copyWith(error: 'Please select an image first.');
      return;
    }

    state = state.copyWith(
      isAnalyzing: true,
      error: null,
      analyzingMessage: _analyzingMessages[0],
    );

    try {
      // Simulate progress messages (reduced delay for faster UX)
      for (int i = 1; i < _analyzingMessages.length; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (state.isAnalyzing) {
          state = state.copyWith(analyzingMessage: _analyzingMessages[i]);
        }
      }

      final ingredients = await _openAIService.recognizeIngredients(
        state.selectedImage!,
      );

      if (ingredients.isEmpty) {
        state = state.copyWith(
          isAnalyzing: false,
          error: 'No ingredients found in the image. Please try a different photo with clear visibility of food items.',
          analyzingMessage: null,
        );
        return;
      }

      // Auto-select all ingredients by default
      final selected = ingredients.map((e) => e.name).toList();

      state = state.copyWith(
        isAnalyzing: false,
        recognizedIngredients: ingredients,
        selectedIngredients: selected,
        analyzingMessage: null,
        error: null,
      );
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Provide more specific error messages
      if (errorMessage.toLowerCase().contains('json')) {
        errorMessage = 'Failed to analyze image. Please try again with a clearer photo.';
      } else if (errorMessage.toLowerCase().contains('api key')) {
        errorMessage = 'API configuration error. Please contact support.';
      } else if (errorMessage.toLowerCase().contains('network') || 
                 errorMessage.toLowerCase().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorMessage.toLowerCase().contains('timeout')) {
        errorMessage = 'Request timed out. Please try again.';
      }
      
      state = state.copyWith(
        isAnalyzing: false,
        error: errorMessage,
        analyzingMessage: null,
      );
    }
  }

  void toggleIngredient(String ingredientName) {
    final current = List<String>.from(state.selectedIngredients);
    if (current.contains(ingredientName)) {
      current.remove(ingredientName);
    } else {
      current.add(ingredientName);
    }
    state = state.copyWith(selectedIngredients: current);
  }

  void addManualIngredient(String ingredient) {
    final trimmed = ingredient.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(state.manualIngredients);
    if (!current.contains(trimmed)) {
      current.add(trimmed);
      state = state.copyWith(manualIngredients: current);
    }
  }

  void removeManualIngredient(String ingredient) {
    final current = List<String>.from(state.manualIngredients);
    current.remove(ingredient);
    state = state.copyWith(manualIngredients: current);
  }

  void retakePhoto() {
    state = state.copyWith(
      selectedImage: null,
      recognizedIngredients: [],
      selectedIngredients: [],
      manualIngredients: [],
      error: null,
    );
  }

  void clearAll() {
    state = const ScanState();
  }
}
