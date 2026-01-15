import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class EmptySavedState extends StatelessWidget {
  const EmptySavedState({super.key, required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.bookmark_border,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved recipes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first recipe and save it here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate recipe'),
            ),
          ],
        ),
      ),
    );
  }
}
