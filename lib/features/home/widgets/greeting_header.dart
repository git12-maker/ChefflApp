import 'package:flutter/material.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greet = _greeting();
    final name = username?.isNotEmpty == true ? username : 'Chef';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greet, $name 👋',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What would you like to cook today?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
