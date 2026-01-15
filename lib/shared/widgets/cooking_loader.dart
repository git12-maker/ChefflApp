import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Animated cooking loader that shows chef is preparing the dish
/// Shows staged progress with cooking-themed messages and icons
class CookingLoader extends StatefulWidget {
  const CookingLoader({
    super.key,
    this.height = 230,
  });

  final double height;

  @override
  State<CookingLoader> createState() => _CookingLoaderState();
}

class _CookingLoaderState extends State<CookingLoader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  int _currentStage = 0;
  Timer? _stageTimer;

  final List<CookingStage> _stages = const [
    CookingStage(
      icon: Icons.restaurant_menu,
      message: 'Preparing ingredients...',
      duration: 3,
    ),
    CookingStage(
      icon: Icons.local_fire_department,
      message: 'Cooking in progress...',
      duration: 4,
    ),
    CookingStage(
      icon: Icons.restaurant,
      message: 'Adding final touches...',
      duration: 3,
    ),
    CookingStage(
      icon: Icons.celebration,
      message: 'Almost ready!',
      duration: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startStageCycle();
  }

  void _startStageCycle() {
    _updateStage();
  }

  void _updateStage() {
    if (!mounted) return;

    setState(() {
      _currentStage = (_currentStage + 1) % _stages.length;
    });

    final stage = _stages[_currentStage];
    _stageTimer = Timer(Duration(seconds: stage.duration), _updateStage);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _stageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentStage = _stages[_currentStage];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(18),
      ),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    AppColors.primaryDark.withOpacity(0.9),
                    AppColors.primary.withOpacity(0.85),
                  ]
                : [
                    AppColors.primary.withOpacity(0.85),
                    AppColors.accent.withOpacity(0.75),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Animated background pattern
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.3,
                  child: CustomPaint(
                    painter: _CookingPatternPainter(
                      color: AppColors.white.withOpacity(0.1),
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStage.icon,
                            size: 48,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Animated message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      currentStage.message,
                      key: ValueKey(currentStage.message),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _stages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentStage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentStage
                              ? AppColors.white
                              : AppColors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CookingStage {
  const CookingStage({
    required this.icon,
    required this.message,
    required this.duration,
  });

  final IconData icon;
  final String message;
  final int duration; // seconds
}

/// Custom painter for subtle cooking pattern in background
class _CookingPatternPainter extends CustomPainter {
  _CookingPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw subtle grid pattern
    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
