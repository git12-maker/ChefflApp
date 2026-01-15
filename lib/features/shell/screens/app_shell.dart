import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../home/screens/home_screen.dart';
import '../../generate/screens/generate_screen.dart';
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
    GenerateScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
        // Keep all pages alive for instant switching (performance vs memory tradeoff)
        sizing: StackFit.expand,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _onTabSelected(index);
          // Update GoRouter location for deep-link consistency
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/generate');
              break;
            case 2:
              context.go('/saved');
              break;
            case 3:
              context.go('/profile');
              break;
            default:
              context.go('/home');
          }
        },
      ),
    );
  }
}
