import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/ingredient_provider.dart';
import 'ingredient_card.dart';

/// Main ingredient selection grid with images
class IngredientSelectionGrid extends ConsumerStatefulWidget {
  const IngredientSelectionGrid({
    super.key,
    required this.selectedIngredients,
    required this.onAdd,
    this.analysisFuture,
  });

  final List<String> selectedIngredients;
  final ValueChanged<String> onAdd;
  final Future<CompositionAnalysis>? analysisFuture;

  @override
  ConsumerState<IngredientSelectionGrid> createState() => _IngredientSelectionGridState();
}

class _IngredientSelectionGridState extends ConsumerState<IngredientSelectionGrid> {
  final TextEditingController _searchController = TextEditingController();
  bool _showBrowse = false;
  List<Ingredient> _suggestedIngredients = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(IngredientSelectionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIngredients.length != widget.selectedIngredients.length ||
        oldWidget.analysisFuture != widget.analysisFuture) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (widget.selectedIngredients.isEmpty) {
      // First ingredient: show ALL carriers
      setState(() => _loadingSuggestions = true);
      try {
        final all = await CulinaryIntelligenceService.instance.getAllIngredients();
        // Show ALL carriers, not just a limited subset
        final carriers = all.where((i) => i.canBeCarrier).toList();
        setState(() {
          _suggestedIngredients = carriers;
          _loadingSuggestions = false;
        });
      } catch (e) {
        setState(() => _loadingSuggestions = false);
      }
      return;
    }

    // Load from analysis
    if (widget.analysisFuture != null) {
      setState(() => _loadingSuggestions = true);
      try {
        final analysis = await widget.analysisFuture;
        if (analysis != null && mounted) {
          // Get ALL suggestions, not just a limited subset
          final suggested = analysis.suggestions
              .map((s) => s.ingredient)
              .where((i) => !widget.selectedIngredients.contains(i.name))
              .toList();
          setState(() {
            _suggestedIngredients = suggested;
            _loadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _loadingSuggestions = false);
      }
    }
  }

  void _shuffleSuggestions() {
    final rnd = Random();
    final shuffled = List<Ingredient>.from(_suggestedIngredients)..shuffle(rnd);
    setState(() => _suggestedIngredients = shuffled);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(ingredientProvider).searchResults;
    final allIngredients = ref.watch(ingredientProvider).allIngredients;
    final categorized = ref.watch(ingredientProvider).categorizedIngredients;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(ingredientProvider.notifier).clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isEmpty) {
                ref.read(ingredientProvider.notifier).clearSearch();
              } else {
                ref.read(ingredientProvider.notifier).search(value);
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onAdd(value.trim());
                _searchController.clear();
              }
            },
          ),
        ),

        // Mode toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Suggestions'),
                icon: Icon(Icons.lightbulb_outline_rounded, size: 18),
              ),
              ButtonSegment(
                value: true,
                label: Text('Browse'),
                icon: Icon(Icons.grid_view_rounded, size: 18),
              ),
            ],
            selected: {_showBrowse},
            onSelectionChanged: (Set<bool> selected) {
              setState(() => _showBrowse = selected.first);
            },
          ),
        ),

        const SizedBox(height: 8),

        // Content
        Expanded(
          child: _showBrowse
              ? _buildBrowseView(context, searchResults, categorized)
              : _buildSuggestionsView(context),
        ),
      ],
    );
  }

  Widget _buildSuggestionsView(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestedIngredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Shuffle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _shuffleSuggestions,
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: const Text('Shuffle'),
            ),
          ),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _suggestedIngredients.length,
            itemBuilder: (context, index) {
              final ingredient = _suggestedIngredients[index];
              final isSelected = widget.selectedIngredients.contains(ingredient.name);
              
              // Determine badge
              String? badgeLabel;
              if (ingredient.canBeCarrier && widget.selectedIngredients.isEmpty) {
                badgeLabel = 'Carrier';
              } else if (ingredient.providesUmami) {
                badgeLabel = 'Umami';
              } else if (ingredient.providesAcidity) {
                badgeLabel = 'Acid';
              }

              return IngredientCard(
                ingredient: ingredient,
                isSelected: isSelected,
                onTap: () => widget.onAdd(ingredient.name),
                showBadge: badgeLabel != null,
                badgeLabel: badgeLabel,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseView(
    BuildContext context,
    List<Ingredient> searchResults,
    Map<String, List<Ingredient>> categorized,
  ) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(ingredientProvider).isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show search results
    if (_searchController.text.isNotEmpty && searchResults.isNotEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final ingredient = searchResults[index];
          final isSelected = widget.selectedIngredients.contains(ingredient.name);
          return IngredientCard(
            ingredient: ingredient,
            isSelected: isSelected,
            onTap: () => widget.onAdd(ingredient.name),
          );
        },
      );
    }

    // Show all ingredients by category
    final allIngredients = categorized.values.expand((list) => list).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = allIngredients[index];
        final isSelected = widget.selectedIngredients.contains(ingredient.name);
        return IngredientCard(
          ingredient: ingredient,
          isSelected: isSelected,
          onTap: () => widget.onAdd(ingredient.name),
        );
      },
    );
  }
}
