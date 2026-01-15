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
    
    print('🚀 [RecipeLoadingScreen] Starting generation...');
    print('🚀 [RecipeLoadingScreen] Current state: recipe=${state.generatedRecipe != null}, isLoading=${state.isLoading}');
    
    // If recipe is already generated, navigate immediately
    if (state.generatedRecipe != null) {
      print('✅ [RecipeLoadingScreen] Recipe already exists, navigating immediately');
      _navigateToRecipe();
      return;
    }
    
    // Set up listener BEFORE starting generation
    // This ensures we catch the state change
    ref.listen<GenerateState>(generateProvider, (previous, next) {
      print('📡 [RecipeLoadingScreen] State changed: recipe=${next.generatedRecipe != null}, error=${next.error}');
      
      // Navigate as soon as recipe is ready (don't wait for image)
      if (next.generatedRecipe != null && !_hasNavigated) {
        print('✅ [RecipeLoadingScreen] Recipe ready in listener, navigating...');
        _controller.markRecipeComplete();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasNavigated) {
            _navigateToRecipe();
          }
        });
      }
      
      // Handle errors
      if (next.error != null && !_hasNavigated) {
        print('❌ [RecipeLoadingScreen] Error in listener: ${next.error}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/generate');
          }
        });
      }
    });
    
    // Start generation (don't await - listener will handle navigation)
    print('🔄 [RecipeLoadingScreen] Calling generateRecipe()...');
    notifier.generateRecipe().then((_) {
      print('✅ [RecipeLoadingScreen] generateRecipe() completed');
    }).catchError((e) {
      print('❌ [RecipeLoadingScreen] generateRecipe() error: $e');
    });
  }

  void _navigateToRecipe() {
    if (_hasNavigated) {
      print('⚠️ [RecipeLoadingScreen] Already navigated, skipping');
      return; // Prevent multiple navigations
    }
    _hasNavigated = true;
    
    final state = ref.read(generateProvider);
    final recipe = state.generatedRecipe;
    
    print('🧭 [RecipeLoadingScreen] Navigating to recipe page...');
    print('🧭 [RecipeLoadingScreen] Recipe: ${recipe?.title ?? "null"}');
    print('🧭 [RecipeLoadingScreen] Mounted: $mounted');
    
    if (recipe != null && mounted) {
      // Navigate to recipe result page
      // Image generation will continue on this page
      print('✅ [RecipeLoadingScreen] Navigating to /recipe-result');
      context.go('/recipe-result', extra: recipe);
    } else {
      // Fallback: go back to generate
      print('⚠️ [RecipeLoadingScreen] Recipe is null or not mounted, going to /generate');
      if (mounted) {
        context.go('/generate');
      }
    }
  }

  void _onLoaderComplete() {
    // Fallback navigation
    print('⏰ [RecipeLoadingScreen] Loader complete callback triggered');
    _navigateToRecipe();
  }

  @override
  Widget build(BuildContext context) {
    // Also watch in build as backup (in case listener doesn't fire)
    final state = ref.watch(generateProvider);
    
    // Check if recipe is ready and navigate (backup check)
    if (state.generatedRecipe != null && !_hasNavigated) {
      print('✅ [RecipeLoadingScreen] Recipe ready in build(), navigating (backup)...');
      _controller.markRecipeComplete();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasNavigated) {
          print('🧭 [RecipeLoadingScreen] Executing navigation from build()');
          _navigateToRecipe();
        }
      });
    }
    
    return RecipeGenerationLoader(
      controller: _controller,
      onComplete: _onLoaderComplete,
      estimatedRecipeTime: 8,
      estimatedImageTime: 12,
    );
  }
}
