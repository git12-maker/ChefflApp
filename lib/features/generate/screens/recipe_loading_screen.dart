import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/generate_provider.dart';
import '../widgets/recipe_generation_loader.dart' show RecipeGenerationLoader, RecipeGenerationLoaderController;

/// Full-screen loading screen for recipe generation
/// Shows progressive steps and navigates to recipe result when complete
class RecipeLoadingScreen extends ConsumerStatefulWidget {
  const RecipeLoadingScreen({super.key});

  @override
  ConsumerState<RecipeLoadingScreen> createState() => _RecipeLoadingScreenState();
}

class _RecipeLoadingScreenState extends ConsumerState<RecipeLoadingScreen> {
  bool _hasStartedGeneration = false;
  bool _hasNavigated = false;
  bool _navigationScheduled = false;
  late final RecipeGenerationLoaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RecipeGenerationLoaderController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start generation once (not in initState to have access to ref)
    if (!_hasStartedGeneration) {
      _hasStartedGeneration = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGeneration();
      });
    }
  }

  Future<void> _startGeneration() async {
    final notifier = ref.read(generateProvider.notifier);
    final state = ref.read(generateProvider);
    
    if (kDebugMode) {
      debugPrint('🚀 [RecipeLoadingScreen] Starting generation...');
    }
    
    // If recipe is already generated, navigate immediately
    if (state.generatedRecipe != null) {
      if (kDebugMode) {
        debugPrint('✅ [RecipeLoadingScreen] Recipe already exists, navigating immediately');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToRecipe();
        }
      });
      return;
    }
    
    // Start generation (don't await - build method will watch for changes)
    notifier.generateRecipe().catchError((e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [RecipeLoadingScreen] generateRecipe() error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Error is handled in provider state, build method will show it
    });
  }

  void _navigateToRecipe() {
    if (_hasNavigated) {
      return; // Prevent multiple navigations
    }
    _hasNavigated = true;
    
    final state = ref.read(generateProvider);
    final recipe = state.generatedRecipe;
    
    if (recipe != null && mounted) {
      // Navigate to recipe result page
      // Image generation will continue on this page
      context.go('/recipe-result', extra: recipe);
    } else {
      // Fallback: go back to generate
      if (mounted) {
        context.go('/generate');
      }
    }
  }

  void _onLoaderComplete() {
    // Fallback navigation
    _navigateToRecipe();
  }

  @override
  Widget build(BuildContext context) {
    // Watch state - this will rebuild whenever state changes
    final state = ref.watch(generateProvider);
    
    // Check if recipe is ready and navigate (only schedule once)
    if (state.generatedRecipe != null && !_hasNavigated && !_navigationScheduled) {
      _navigationScheduled = true;
      _controller.markRecipeComplete();
      
      // Navigate immediately (use postFrameCallback to avoid navigation during build)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasNavigated) {
          _navigateToRecipe();
        }
      });
    }
    
    // Handle errors - show error and navigate back after delay
    if (state.error != null && !_hasNavigated && !_navigationScheduled) {
      _navigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Show error briefly, then navigate back
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/generate');
            }
          });
        }
      });
    }
    
    // Show error overlay if there's an error
    return Stack(
      children: [
        RecipeGenerationLoader(
          controller: _controller,
          onComplete: _onLoaderComplete,
          estimatedRecipeTime: 5, // Reduced from 8 - recipe is usually ready in 3-5 sec
          estimatedImageTime: 12,
        ),
        if (state.error != null)
          Container(
            color: Colors.red.withOpacity(0.1),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Returning to generate screen...',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
