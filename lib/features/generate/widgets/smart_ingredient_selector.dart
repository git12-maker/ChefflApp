import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import 'composition_advisor.dart';
import 'flavor_balance_indicator.dart';

/// Smart ingredient selector with culinary intelligence
/// Provides dynamic suggestions based on flavor science and composition analysis
class SmartIngredientSelector extends ConsumerStatefulWidget {
  const SmartIngredientSelector({
    super.key,
    required this.selectedIngredients,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> selectedIngredients;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  @override
  ConsumerState<SmartIngredientSelector> createState() => _SmartIngredientSelectorState();
}

class _SmartIngredientSelectorState extends ConsumerState<SmartIngredientSelector> {
  String _selectedCategory = 'All';
  bool _showAnalysis = true; // Show by default when ingredients are selected
  CompositionAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _analyzeIfNeeded();
  }

  @override
  void didUpdateWidget(SmartIngredientSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIngredients.length != widget.selectedIngredients.length) {
      _analyzeIfNeeded();
    }
  }

  Future<void> _analyzeIfNeeded() async {
    if (widget.selectedIngredients.isNotEmpty) {
      final analysis = await CulinaryIntelligenceService.instance
          .analyzeComposition(widget.selectedIngredients);
      if (mounted) {
        setState(() {
          _analysis = analysis;
        });
      }
    } else {
      setState(() {
        _analysis = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredientState = ref.watch(ingredientProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chef's Analysis (when ingredients are selected)
        if (widget.selectedIngredients.isNotEmpty && _analysis != null) ...[
          _buildAnalysisSection(context),
          const SizedBox(height: 24),
        ],
        
        // Browse Ingredients section
        Text(
          'Browse Ingredients',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Category tabs
        _buildCategoryTabs(context, ingredientState),
        const SizedBox(height: 12),
        
        // Ingredient grid
        _buildIngredientGrid(context, ingredientState),
      ],
    );
  }

  Widget _buildAnalysisSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button
        InkWell(
          onTap: () => setState(() => _showAnalysis = !_showAnalysis),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showAnalysis ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chef\'s Analysis',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getScoreColor(_analysis!.overallScore).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_analysis!.overallScore}/100',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getScoreColor(_analysis!.overallScore),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded analysis
        if (_showAnalysis) ...[
          const SizedBox(height: 12),
          // Flavor balance
          FlavorBalanceIndicator(flavorProfile: _analysis!.flavorProfile),
          const SizedBox(height: 12),
          // Composition advisor with suggestions
          CompositionAdvisor(
            analysis: _analysis!,
            onSuggestionTap: widget.onAdd,
          ),
        ] else if (_analysis!.suggestions.isNotEmpty) ...[
          // Show compact suggestions when collapsed
          const SizedBox(height: 8),
          _buildQuickSuggestions(context),
        ],
      ],
    );
  }

  Widget _buildQuickSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _analysis!.suggestions.take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 6),
            Text(
              'Try adding:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) => _QuickSuggestionChip(
            name: s.ingredient.name,
            reason: s.reason,
            onTap: () => widget.onAdd(s.ingredient.name),
          )).toList(),
        ),
      ],
    );
  }


  Widget _buildCategoryTabs(BuildContext context, IngredientSelectionState state) {
    final theme = Theme.of(context);
    
    // Get categories from state
    final categories = ['All', ...state.categorizedIngredients.keys.toList()..sort()];
    
    if (state.isLoading) {
      return const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIngredientGrid(BuildContext context, IngredientSelectionState state) {
    final theme = Theme.of(context);
    
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Get ingredients for selected category
    List<Ingredient> ingredients;
    if (_selectedCategory == 'All') {
      ingredients = state.allIngredients;
    } else {
      ingredients = state.categorizedIngredients[_selectedCategory] ?? [];
    }
    
    // Sort: show most useful for current composition first (if analysis exists)
    if (_analysis != null && _analysis!.suggestions.isNotEmpty) {
      final suggestionIds = _analysis!.suggestions.map((s) => s.ingredient.id).toSet();
      ingredients = [...ingredients]..sort((a, b) {
        final aIsSuggested = suggestionIds.contains(a.id) ? 0 : 1;
        final bIsSuggested = suggestionIds.contains(b.id) ? 0 : 1;
        return aIsSuggested.compareTo(bIsSuggested);
      });
    }
    
    // Limit to prevent performance issues
    ingredients = ingredients.take(100).toList();
    
    if (ingredients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedCategory == 'All' 
                    ? 'No ingredients found'
                    : 'No ingredients in this category',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ingredients.map((ingredient) {
        final isSelected = widget.selectedIngredients
            .any((s) => s.toLowerCase() == ingredient.name.toLowerCase() ||
                        s.toLowerCase() == ingredient.nameNl?.toLowerCase());
        final isSuggested = _analysis?.suggestions
            .any((s) => s.ingredient.id == ingredient.id) ?? false;
        
        return _IngredientChip(
          ingredient: ingredient,
          isSelected: isSelected,
          isSuggested: isSuggested && !isSelected,
          onTap: () {
            if (isSelected) {
              widget.onRemove(ingredient.name);
            } else {
              widget.onAdd(ingredient.name);
            }
          },
        );
      }).toList(),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red.shade400;
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({
    required this.ingredient,
    required this.isSelected,
    required this.isSuggested,
    required this.onTap,
  });

  final Ingredient ingredient;
  final bool isSelected;
  final bool isSuggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isSelected) {
      backgroundColor = AppColors.primary.withOpacity(isDark ? 0.3 : 0.15);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    } else if (isSuggested) {
      backgroundColor = Colors.amber.withOpacity(isDark ? 0.2 : 0.1);
      borderColor = Colors.amber;
      textColor = Colors.amber.shade700;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
      borderColor = theme.colorScheme.outlineVariant;
      textColor = theme.colorScheme.onSurface;
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected || isSuggested ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: textColor,
                  ),
                )
              else if (isSuggested)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: textColor,
                  ),
                ),
              Text(
                ingredient.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSuggestionChip extends StatelessWidget {
  const _QuickSuggestionChip({
    required this.name,
    required this.reason,
    required this.onTap,
  });

  final String name;
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Tooltip(
      message: reason,
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(name),
          ],
        ),
        onPressed: onTap,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.3),
        ),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
