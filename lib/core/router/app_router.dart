import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/generate/screens/recipe_result_screen.dart';
import '../../features/generate/screens/recipe_loading_screen.dart';
import '../../features/recipe/screens/recipe_detail_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/shell/screens/app_shell.dart';
import '../../services/supabase_service.dart';
import '../../shared/models/recipe.dart';

/// App router configuration using go_router
class AppRouter {
  AppRouter._();

  /// Static router instance
  static final GoRouter router = _createRouter();

  /// Create router with auth guards
  static GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/home',
      redirect: (context, state) {
        final isAuthenticated = SupabaseService.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot-password';

        // If not authenticated and trying to access protected route, redirect to login
        if (!isAuthenticated && !isAuthRoute && state.matchedLocation != '/') {
          return '/login';
        }

        // If authenticated and trying to access auth routes, redirect to home
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        return null; // No redirect needed
      },
      routes: [
        // Auth routes (public)
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Shell with bottom navigation
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const AppShell(initialIndex: 0),
        ),
        GoRoute(
          path: '/generate',
          name: 'generate',
          builder: (context, state) {
            // Handle initial ingredients from route extra
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              final ingredients = extra['ingredients'] as List<String>?;
              if (ingredients != null && ingredients.isNotEmpty) {
                // Set ingredients in provider (will be handled by GenerateScreen)
                // We can't access ref here, so GenerateScreen will handle it
              }
            }
            return const AppShell(initialIndex: 1);
          },
        ),
        GoRoute(
          path: '/saved',
          name: 'saved',
          builder: (context, state) => const AppShell(initialIndex: 2),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const AppShell(initialIndex: 3),
        ),

        // Detail routes
        GoRoute(
          path: '/recipe/:id',
          name: 'recipe-detail',
          builder: (context, state) {
            final recipe = state.extra as Recipe?;
            if (recipe == null) {
              return const _PlaceholderScreen(title: 'Recipe Detail');
            }
            return RecipeDetailScreen(recipe: recipe);
          },
        ),
            GoRoute(
              path: '/recipe-result',
              name: 'recipe-result',
              builder: (context, state) {
                final recipe = state.extra as Recipe?;
                if (recipe == null) {
                  return const _PlaceholderScreen(title: 'Recipe');
                }
                return RecipeResultScreen(recipe: recipe);
              },
            ),
            GoRoute(
              path: '/recipe-loading',
              name: 'recipe-loading',
              builder: (context, state) => const RecipeLoadingScreen(),
            ),
            GoRoute(
              path: '/scan',
              name: 'scan',
              builder: (context, state) => const ScanScreen(),
            ),
      ],
    );
  }

}

/// Placeholder screen for routes that will be implemented later
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isHome = title.toLowerCase() == 'home';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (isHome) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/generate'),
                child: const Text('Go to Generate'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
