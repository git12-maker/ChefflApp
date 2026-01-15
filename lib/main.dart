import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'shared/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase before running the app
  try {
    await SupabaseService.initialize();
  } catch (e) {
    // If Supabase initialization fails, log error but continue
    // This allows the app to run even if credentials are not set yet
    debugPrint('Supabase initialization error: $e');
    debugPrint(
      'Please update lib/core/constants/env.dart with your Supabase credentials.',
    );
  }

  runApp(
    const ProviderScope(
      child: ChefflApp(),
    ),
  );
  
  // Enable performance overlays in debug mode
  // Uncomment to see performance metrics:
  // debugProfileBuildsEnabled = true;
}

/// Main app widget
class ChefflApp extends ConsumerWidget {
  const ChefflApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Cheffl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
