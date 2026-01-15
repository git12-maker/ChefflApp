import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.email,
    this.memberSince,
    this.avatarUrl,
  });

  final String email;
  final DateTime? memberSince;
  final String? avatarUrl;

  String get _initials {
    final parts = email.split('@');
    if (parts.isEmpty) return 'U';
    final name = parts[0];
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get _memberSinceText {
    if (memberSince == null) return 'Member';
    final now = DateTime.now();
    final diff = now.difference(memberSince!);
    final years = diff.inDays ~/ 365;
    if (years > 0) {
      return 'Member since ${memberSince!.year}';
    }
    final months = diff.inDays ~/ 30;
    if (months > 0) {
      return 'Member for $months ${months == 1 ? 'month' : 'months'}';
    }
    return 'New member';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(theme),
                    ),
                  )
                : _buildInitials(theme),
          ),
          const SizedBox(width: 16),
          // Email and member since
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _memberSinceText,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildInitials(ThemeData theme) {
    return Center(
      child: Text(
        _initials,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
