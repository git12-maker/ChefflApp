import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Minimal progress indicator showing selected count and score
class MinimalProgressIndicator extends StatelessWidget {
  const MinimalProgressIndicator({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '$selectedCount selected',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (score != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(score!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getScoreColor(score!),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline_rounded,
                size: 16,
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
