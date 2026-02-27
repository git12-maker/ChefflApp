import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Compact header showing score and selected ingredients count
class CompactHeaderBar extends StatelessWidget {
  const CompactHeaderBar({
    super.key,
    required this.selectedCount,
    this.score,
    this.onTap,
  });

  final int selectedCount;
  final int? score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Selected count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$selectedCount',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Score
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(score!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _getScoreColor(score!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: _getScoreColor(score!),
                    ),
                  ],
                ),
              ),
            
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
