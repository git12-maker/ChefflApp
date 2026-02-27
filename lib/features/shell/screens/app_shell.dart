import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../home/providers/home_provider.dart';
import '../../saved/providers/saved_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../generate/screens/generate_screen_simple.dart';
import '../../saved/screens/saved_screen.dart';
import '../../profile/screens/profile_screen.dart';
/// App shell with bottom navigation and tab state management.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _currentIndex;
  final _pages = const [
    HomeScreen(),
    GenerateScreenSimple(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // Refresh when switching tabs (new recipes, favorites, images)
    if (index == 2) {
      ref.read(savedProvider.notifier).refresh();
    } else if (index == 0) {
      ref.read(homeProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        sizing: StackFit.expand,
        // Keep all pages alive for instant switching (performance vs memory tradeoff)
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                // Update state first for instant visual feedback
                _onTabSelected(index);
                
                // Update GoRouter location for deep-link consistency
                // Use a post-frame callback to ensure state update completes first
                // This prevents the confusing double-page effect
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final targetRoute = _getRouteForIndex(index);
                  final currentRoute = GoRouterState.of(context).matchedLocation;
                  
                  // Only navigate if route is different (prevents unnecessary rebuilds)
                  if (currentRoute != targetRoute) {
                    context.go(targetRoute);
                  }
                });
              },
            ),
    );
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/generate';
      case 2:
        return '/saved';
      case 3:
        return '/profile';
      default:
        return '/home';
    }
  }
}
