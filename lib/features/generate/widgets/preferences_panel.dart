import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/recipe_preferences.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../services/preferences_service.dart';

class PreferencesPanel extends StatefulWidget {
  const PreferencesPanel({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final RecipePreferences preferences;
  final void Function(RecipePreferences) onChanged;

  @override
  State<PreferencesPanel> createState() => _PreferencesPanelState();
}

class _PreferencesPanelState extends State<PreferencesPanel> {
  UserPreferences? _userPreferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await PreferencesService.instance.getPreferences();
      setState(() {
        _userPreferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool get _hasDefaultPreferences {
    if (_userPreferences == null) return false;
    
    final hasDefaultServings = widget.preferences.servings == _userPreferences!.defaultServings;
    final hasDefaultDietary = widget.preferences.dietaryRestrictions.length == 
        _userPreferences!.dietaryPreferences.length &&
        widget.preferences.dietaryRestrictions.every(
          (r) => _userPreferences!.dietaryPreferences.contains(r),
        );
    
    final selectedCuisines = [
      if (widget.preferences.cuisine != null) widget.preferences.cuisine!,
      ...widget.preferences.cuisineInfluences,
    ];
    final hasDefaultCuisine = _userPreferences!.preferredCuisines.isNotEmpty
        ? selectedCuisines.length == _userPreferences!.preferredCuisines.length &&
          selectedCuisines.every((c) => _userPreferences!.preferredCuisines.contains(c))
        : selectedCuisines.isEmpty;
    
    return hasDefaultServings && hasDefaultDietary && hasDefaultCuisine;
  }

  /// Build summary badges for selected preferences
  List<Widget> _buildSelectedPreferencesSummary() {
    final badges = <Widget>[];
    
    // Servings
    badges.add(_SummaryBadge(
      label: '${widget.preferences.servings} servings',
      icon: Icons.people_alt_outlined,
    ));
    
    // Difficulty
    if (widget.preferences.difficulty != null) {
      badges.add(_SummaryBadge(
        label: widget.preferences.difficulty!.substring(0, 1).toUpperCase() + 
               widget.preferences.difficulty!.substring(1),
        icon: Icons.terrain_outlined,
      ));
    }
    
    // Max time
    if (widget.preferences.maxTimeMinutes != null) {
      badges.add(_SummaryBadge(
        label: '${widget.preferences.maxTimeMinutes} min',
        icon: Icons.timer_outlined,
      ));
    }
    
    // Cuisines
    final selectedCuisines = [
      if (widget.preferences.cuisine != null) widget.preferences.cuisine!,
      ...widget.preferences.cuisineInfluences,
    ];
    if (selectedCuisines.isNotEmpty) {
      final cuisineText = selectedCuisines.length == 1
          ? selectedCuisines.first
          : '${selectedCuisines.first} + ${selectedCuisines.length - 1}';
      badges.add(_SummaryBadge(
        label: cuisineText,
        icon: Icons.restaurant_menu_outlined,
      ));
    } else {
      // Show "Any" when no cuisines selected (default)
      badges.add(_SummaryBadge(
        label: 'Any',
        icon: Icons.restaurant_menu_outlined,
      ));
    }
    
    // Dietary tags (show count if more than 2, otherwise show names)
    if (widget.preferences.dietaryRestrictions.isNotEmpty) {
      final dietaryText = widget.preferences.dietaryRestrictions.length <= 2
          ? widget.preferences.dietaryRestrictions.join(', ')
          : '${widget.preferences.dietaryRestrictions.length} dietary';
      badges.add(_SummaryBadge(
        label: dietaryText,
        icon: Icons.local_dining_outlined,
      ));
    }
    
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSummary = _buildSelectedPreferencesSummary();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default preferences indicator
        if (_hasDefaultPreferences && !_isLoading) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using your default preferences from Profile',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedSummary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedSummary,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'No preferences selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Adjust Preferences'),
              children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServingsSelector(context),
                  const SizedBox(height: 24),
                  _buildDifficultySelector(context),
                  const SizedBox(height: 24),
                  _buildMaxTimeSelector(context),
                  const SizedBox(height: 24),
                  _buildCuisineSelector(context),
                  const SizedBox(height: 24),
                  _buildDietarySelector(context),
                ],
              ),
            ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServingsSelector(BuildContext context) {
    final isDefault = _userPreferences != null && 
        widget.preferences.servings == _userPreferences!.defaultServings;
    
    return _PreferenceSection(
      title: 'Servings',
      isDefault: isDefault,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(8, (i) => i + 1).map((servings) {
          final isSelected = widget.preferences.servings == servings;
          return _PreferenceBadge(
            label: '$servings',
            isSelected: isSelected,
            isDefault: isDefault && isSelected,
            onTap: () {
              widget.onChanged(widget.preferences.copyWith(servings: servings));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultySelector(BuildContext context) {
    final difficulties = ['easy', 'medium', 'hard'];
    final isAny = widget.preferences.difficulty == null;
    
    return _PreferenceSection(
      title: 'Difficulty',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PreferenceBadge(
            label: 'Any',
            isSelected: isAny,
            onTap: () {
              widget.onChanged(widget.preferences.copyWith(difficulty: null));
            },
          ),
          ...difficulties.map((difficulty) {
            final isSelected = widget.preferences.difficulty == difficulty;
            return _PreferenceBadge(
              label: difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1),
              isSelected: isSelected,
              onTap: () {
                widget.onChanged(widget.preferences.copyWith(difficulty: difficulty));
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaxTimeSelector(BuildContext context) {
    final timeOptions = [15, 30, 45, 60, 90, 120];
    final currentTime = widget.preferences.maxTimeMinutes;
    final isAny = currentTime == null;
    
    return _PreferenceSection(
      title: 'Max Cooking Time',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PreferenceBadge(
            label: 'Any',
            isSelected: isAny,
            onTap: () {
              widget.onChanged(widget.preferences.copyWith(maxTimeMinutes: null));
            },
          ),
          ...timeOptions.map((minutes) {
            final isSelected = currentTime == minutes;
            return _PreferenceBadge(
              label: '$minutes min',
              isSelected: isSelected,
              onTap: () {
                widget.onChanged(widget.preferences.copyWith(maxTimeMinutes: minutes));
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCuisineSelector(BuildContext context) {
    // Get all available cuisines
    const standardCuisines = [
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
    
    final allCuisines = <String>{};
    if (_userPreferences != null && _userPreferences!.preferredCuisines.isNotEmpty) {
      allCuisines.addAll(_userPreferences!.preferredCuisines);
    }
    allCuisines.addAll(standardCuisines);
    final sortedCuisines = allCuisines.toList()..sort();
    
    // Get selected cuisines
    final selectedCuisines = <String>{};
    if (widget.preferences.cuisine != null) {
      selectedCuisines.add(widget.preferences.cuisine!);
    }
    selectedCuisines.addAll(widget.preferences.cuisineInfluences);
    
    // Check if "Any" is selected (no cuisines selected)
    final isAny = selectedCuisines.isEmpty;
    
    // Check if matches defaults (no cuisines selected when no defaults in profile)
    final defaultCuisines = _userPreferences?.preferredCuisines.toSet() ?? {};
    final isDefault = defaultCuisines.isEmpty && isAny;
    
    return _PreferenceSection(
      title: 'Cuisine',
      isDefault: isDefault,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // "Any" option - always first
          _PreferenceBadge(
            label: 'Any',
            isSelected: isAny,
            isDefault: isDefault,
            onTap: () {
              // Clear all cuisines when "Any" is selected
              widget.onChanged(
                widget.preferences.copyWith(
                  cuisine: null,
                  cuisineInfluences: [],
                ),
              );
            },
          ),
          // All cuisine options
          ...sortedCuisines.map((cuisine) {
            final isSelected = selectedCuisines.contains(cuisine);
            final isDefaultCuisine = defaultCuisines.contains(cuisine);
            
            return _PreferenceBadge(
              label: cuisine,
              isSelected: isSelected,
              isDefault: isDefaultCuisine && isSelected,
              onTap: () {
                final newSelected = Set<String>.from(selectedCuisines);
                if (isSelected) {
                  newSelected.remove(cuisine);
                } else {
                  newSelected.add(cuisine);
                }
                
                // Update preferences: first selected is primary, rest are influences
                final newList = newSelected.toList();
                widget.onChanged(
                  widget.preferences.copyWith(
                    cuisine: newList.isNotEmpty ? newList.first : null,
                    cuisineInfluences: newList.length > 1 ? newList.sublist(1) : [],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDietarySelector(BuildContext context) {
    const standardTags = [
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'Keto',
      'Paleo',
      'Low-Carb',
      'Low-Fat',
      'Sugar-Free',
    ];
    
    final allTags = <String>{};
    if (_userPreferences != null) {
      allTags.addAll(_userPreferences!.dietaryPreferences);
    }
    allTags.addAll(standardTags);
    final sortedTags = allTags.toList()..sort();
    
    final defaultTags = _userPreferences?.dietaryPreferences
        .map((p) => p.toLowerCase())
        .toSet() ?? {};
    
    return _PreferenceSection(
      title: 'Dietary Tags',
      isDefault: defaultTags.isNotEmpty &&
          widget.preferences.dietaryRestrictions.length == defaultTags.length &&
          widget.preferences.dietaryRestrictions.every(
            (r) => defaultTags.contains(r.toLowerCase()),
          ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sortedTags.map((tag) {
          final tagLower = tag.toLowerCase();
          final isSelected = widget.preferences.dietaryRestrictions
              .any((r) => r.toLowerCase() == tagLower);
          final isDefaultTag = defaultTags.contains(tagLower);
          
          return _PreferenceBadge(
            label: tag,
            isSelected: isSelected,
            isDefault: isDefaultTag && isSelected,
            onTap: () {
              final current = List<String>.from(widget.preferences.dietaryRestrictions);
              if (isSelected) {
                current.removeWhere((r) => r.toLowerCase() == tagLower);
              } else {
                if (!current.any((r) => r.toLowerCase() == tagLower)) {
                  current.add(tag);
                }
              }
              widget.onChanged(
                widget.preferences.copyWith(dietaryRestrictions: current),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Section header for preference groups
class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.title,
    required this.child,
    this.isDefault = false,
  });

  final String title;
  final Widget child;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Default',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Summary badge for selected preferences display
class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge widget for preference selection
class _PreferenceBadge extends StatelessWidget {
  const _PreferenceBadge({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDefault = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: isDefault
                        ? [
                            AppColors.primary.withOpacity(isDark ? 0.3 : 0.2),
                            AppColors.primaryDark.withOpacity(isDark ? 0.2 : 0.15),
                          ]
                        : [
                            AppColors.primary.withOpacity(isDark ? 0.25 : 0.15),
                            AppColors.accent.withOpacity(isDark ? 0.15 : 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withOpacity(isDark ? 0.4 : 0.3)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
