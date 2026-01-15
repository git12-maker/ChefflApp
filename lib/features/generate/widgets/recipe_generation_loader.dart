import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Controller to update loader state from outside
class RecipeGenerationLoaderController {
  _RecipeGenerationLoaderState? _state;
  
  void _attach(_RecipeGenerationLoaderState state) {
    _state = state;
  }
  
  void markRecipeComplete() {
    _state?.markRecipeComplete();
  }
  
  void markImageComplete() {
    _state?.markImageComplete();
  }
}

/// World-class loading screen for recipe generation
/// Implements progressive disclosure, time estimates, and smooth animations
class RecipeGenerationLoader extends StatefulWidget {
  const RecipeGenerationLoader({
    super.key,
    required this.onComplete,
    this.controller,
    this.estimatedRecipeTime = 5, // seconds - reduced, recipe is usually ready in 3-5 sec
    this.estimatedImageTime = 12, // seconds
  });

  final VoidCallback onComplete;
  final RecipeGenerationLoaderController? controller;
  final int estimatedRecipeTime;
  final int estimatedImageTime;

  @override
  State<RecipeGenerationLoader> createState() => _RecipeGenerationLoaderState();
}

class _RecipeGenerationLoaderState extends State<RecipeGenerationLoader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _recipeComplete = false;
  bool _imageComplete = false;
  
  // Estimated times in seconds
  int get _totalEstimatedTime => 
      widget.estimatedRecipeTime + widget.estimatedImageTime;

  @override
  void initState() {
    super.initState();
    
    // Attach controller if provided
    widget.controller?._attach(this);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalEstimatedTime),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    
    // Start progress animation
    _progressController.forward();
    
    // Start timer for elapsed time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void markRecipeComplete() {
    if (mounted) {
      setState(() {
        _recipeComplete = true;
        // Speed up progress animation when recipe is complete
        // Adjust progress controller to complete faster
        if (_progressController.value < 0.5) {
          _progressController.value = 0.5; // Jump to 50% when recipe is done
        }
      });
    }
  }

  void markImageComplete() {
    if (mounted) {
      setState(() {
        _imageComplete = true;
      });
      // Complete after short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    }
  }
  

  double get _overallProgress {
    if (_recipeComplete && _imageComplete) return 1.0;
    if (_recipeComplete) {
      return 0.5 + (_progressController.value * 0.5);
    }
    return _progressController.value * 0.5;
  }

  String get _timeRemaining {
    final remaining = _totalEstimatedTime - _elapsedSeconds;
    if (remaining <= 0) return 'Almost done...';
    if (remaining < 60) return '~$remaining seconds';
    final minutes = remaining ~/ 60;
    return '~$minutes minute${minutes > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar at top
              _buildProgressBar(theme),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Main animation
                        _buildMainAnimation(theme, isDark),
                        
                        const SizedBox(height: 48),
                        
                        // Status text
                        _buildStatusText(theme),
                        
                        const SizedBox(height: 32),
                        
                        // Time estimate
                        _buildTimeEstimate(theme),
                        
                        const SizedBox(height: 48),
                        
                        // Step indicators
                        _buildStepIndicators(theme),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _overallProgress,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          );
        },
      ),
    );
  }

  Widget _buildMainAnimation(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.1);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    String statusText;
    if (_recipeComplete && _imageComplete) {
      statusText = 'Recipe ready!';
    } else if (_recipeComplete) {
      statusText = 'Creating beautiful image...';
    } else {
      statusText = 'Crafting your perfect recipe...';
    }

    return Column(
      children: [
        Text(
          statusText,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _getSubtitle(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getSubtitle() {
    if (_recipeComplete && _imageComplete) {
      return 'Your recipe is ready to explore';
    } else if (_recipeComplete) {
      return 'Making it look as good as it tastes';
    } else {
      final messages = [
        'Analyzing your ingredients...',
        'Finding the perfect flavor combinations...',
        'Creating step-by-step instructions...',
        'Optimizing cooking times...',
      ];
      final index = (_elapsedSeconds ~/ 2) % messages.length;
      return messages[index];
    }
  }

  Widget _buildTimeEstimate(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            _timeRemaining,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicators(ThemeData theme) {
    return Column(
      children: [
        _buildStepIndicator(
          theme,
          'Recipe Generation',
          _recipeComplete,
          Icons.menu_book_rounded,
        ),
        const SizedBox(height: 16),
        _buildStepIndicator(
          theme,
          'Image Creation',
          _imageComplete,
          Icons.image_rounded,
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    ThemeData theme,
    String label,
    bool isComplete,
    IconData icon,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? AppColors.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isComplete
                ? Icon(
                    Icons.check_circle_rounded,
                    key: const ValueKey('check'),
                    color: AppColors.primary,
                    size: 24,
                  )
                : SizedBox(
                    key: const ValueKey('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isComplete
                        ? AppColors.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete ? 'Complete' : 'In progress...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
