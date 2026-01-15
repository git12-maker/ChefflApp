import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_card.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_selector.dart';
import '../widgets/dietary_preferences_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final user = SupabaseService.getCurrentUser();
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.load(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ProfileHeader(
                email: user?.email ?? 'No email',
                memberSince: user?.createdAt != null
                    ? DateTime.tryParse(user!.createdAt)
                    : null,
              ),
              
              // Stats
              StatsCard(
                totalRecipes: state.totalRecipes,
                favoritesCount: state.favoritesCount,
                recipesThisMonth: state.recipesThisMonth,
              ),

              // Preferences Section
              SettingsSection(
                title: 'Preferences',
                children: [
                  SettingsTile(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Dietary Preferences',
                    subtitle: state.preferences.dietaryPreferences.isEmpty
                        ? 'None selected'
                        : state.preferences.dietaryPreferences.join(', '),
                    onTap: () => _showDietaryPreferencesSheet(
                      context,
                      state.preferences.dietaryPreferences,
                      notifier.updateDietaryPreferences,
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.people_outline,
                    title: 'Default Servings',
                    subtitle: '${state.preferences.defaultServings} servings',
                    onTap: () => _showServingsPicker(
                      context,
                      state.preferences.defaultServings,
                      notifier.updateDefaultServings,
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.public_outlined,
                    title: 'Preferred Cuisines',
                    subtitle: state.preferences.preferredCuisines.isEmpty
                        ? 'None selected'
                        : state.preferences.preferredCuisines.join(', '),
                    onTap: () => _showCuisinesPicker(
                      context,
                      state.preferences.preferredCuisines,
                      notifier.updatePreferredCuisines,
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.straighten_outlined,
                    title: 'Measurement Units',
                    subtitle: state.preferences.measurementUnit.displayName,
                    trailing: Switch(
                      value: state.preferences.measurementUnit ==
                          MeasurementUnit.metric,
                      onChanged: (isMetric) {
                        notifier.updateMeasurementUnit(
                          isMetric
                              ? MeasurementUnit.metric
                              : MeasurementUnit.imperial,
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Appearance Section
              SettingsSection(
                title: 'Appearance',
                children: [
                  ThemeSelector(
                    currentTheme: themeMode,
                    onChanged: (mode) {
                      themeNotifier.setThemeMode(mode);
                    },
                  ),
                ],
              ),

              // Account Section
              SettingsSection(
                title: 'Account',
                children: [
                  SettingsTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Coming soon',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: user?.email != null ? 'Update your password' : null,
                    onTap: user?.email != null
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent!'),
                              ),
                            );
                          }
                        : null,
                  ),
                  SettingsTile(
                    icon: Icons.download_outlined,
                    title: 'Export My Data',
                    subtitle: 'Coming soon',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    isDestructive: true,
                    onTap: () => _showDeleteAccountDialog(context, notifier),
                  ),
                ],
              ),

              // About Section
              SettingsSection(
                title: 'About',
                children: [
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: _appVersion ?? 'Loading...',
                  ),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terms of Service - Coming soon'),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy - Coming soon'),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.star_outline,
                    title: 'Rate the App',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rate the App - Coming soon'),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.email_outlined,
                    title: 'Contact Support',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact Support - Coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, notifier),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withOpacity(0.5),
                        width: 1.5,
                      ),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDietaryPreferencesSheet(
    BuildContext context,
    List<String> current,
    ValueChanged<List<String>> onSave,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DietaryPreferencesSheet(
        selectedPreferences: current,
        onSave: (preferences) {
          onSave(preferences);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showServingsPicker(
    BuildContext context,
    int current,
    ValueChanged<int> onSave,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        int selected = current;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Default Servings'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(8, (index) {
                    final servings = index + 1;
                    return RadioListTile<int>(
                      title: Text('$servings ${servings == 1 ? 'serving' : 'servings'}'),
                      value: servings,
                      groupValue: selected,
                      onChanged: (value) {
                        setState(() => selected = value!);
                      },
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onSave(selected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCuisinesPicker(
    BuildContext context,
    List<String> current,
    ValueChanged<List<String>> onSave,
  ) {
    const cuisines = [
      'Italian',
      'Asian',
      'Mexican',
      'French',
      'Indian',
      'Mediterranean',
      'American',
      'Japanese',
      'Thai',
      'Chinese',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<String> selected = List.from(current);
            
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Preferred Cuisines',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            onSave(selected);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cuisines.length,
                      itemBuilder: (context, index) {
                        final cuisine = cuisines[index];
                        final isSelected = selected.contains(cuisine);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (isSelected) {
                                selected.remove(cuisine);
                              } else {
                                selected.add(cuisine);
                              }
                            });
                          },
                          title: Text(cuisine),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, ProfileNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    ProfileNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion - Coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
