import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/generate_provider.dart';
import '../providers/ingredient_provider.dart';
import 'ingredient_feedback_card.dart';
import 'step_feedback_panel.dart';
import 'ingredient_detail_sheet.dart';

/// Compact ingredient selection with step-by-step feedback
class CompactIngredientGrid extends ConsumerStatefulWidget {
  const CompactIngredientGrid({
    super.key,
    required this.selectedIngredients,
    required this.onAdd,
    this.analysisFuture,
  });

  final List<String> selectedIngredients;
  final ValueChanged<String> onAdd;
  final Future<CompositionAnalysis>? analysisFuture;

  @override
  ConsumerState<CompactIngredientGrid> createState() => _CompactIngredientGridState();
}

class _CompactIngredientGridState extends ConsumerState<CompactIngredientGrid> {
  final TextEditingController _searchController = TextEditingController();
  int _viewMode = 0; // 0 = suggestions, 1 = browse
  List<Ingredient> _suggestedIngredients = [];
  bool _loadingSuggestions = false;
  Ingredient? _lastAddedIngredient;
  CompositionAnalysis? _currentAnalysis;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadAnalysis();
  }

  @override
  void didUpdateWidget(CompactIngredientGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIngredients.length != widget.selectedIngredients.length ||
        oldWidget.analysisFuture != widget.analysisFuture) {
      _loadSuggestions();
      _loadAnalysis();
    }
  }

  Future<void> _loadAnalysis() async {
    if (widget.analysisFuture != null) {
      try {
        final analysis = await widget.analysisFuture;
        if (mounted) {
          setState(() => _currentAnalysis = analysis);
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  Future<void> _loadSuggestions() async {
    if (widget.selectedIngredients.isEmpty) {
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
    if (_suggestedIngredients.isEmpty) return;
    final rnd = Random();
    // Shuffle all suggestions, not just a subset
    final shuffled = List<Ingredient>.from(_suggestedIngredients)..shuffle(rnd);
    setState(() => _suggestedIngredients = shuffled);
  }

  void _handleIngredientTap(Ingredient ingredient) {
    widget.onAdd(ingredient.name);
    
    // Find full ingredient object
    final fullIngredient = _suggestedIngredients.firstWhere(
      (i) => i.name == ingredient.name,
      orElse: () => ingredient,
    );
    
    setState(() {
      _lastAddedIngredient = fullIngredient;
    });
    
    // Auto-dismiss feedback after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _lastAddedIngredient = null);
      }
    });
  }

  void _showIngredientDetail(BuildContext context, Ingredient ingredient) {
    final state = ref.read(generateProvider);
    final selectedMethod = state.cookingMethods[ingredient.name];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IngredientDetailSheet(
        ingredient: ingredient,
        onCookingMethodSelected: (method) {
          ref.read(generateProvider.notifier).setCookingMethod(
            ingredient.name,
            method,
          );
        },
      ),
    );
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

    return Column(
      children: [
        // Compact search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(ingredientProvider.notifier).clearSearch();
                              setState(() {});
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isEmpty) {
                      ref.read(ingredientProvider.notifier).clearSearch();
                    } else {
                      ref.read(ingredientProvider.notifier).search(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Mode toggle
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.lightbulb_outline_rounded, size: 18)),
                  ButtonSegment(value: 1, icon: Icon(Icons.grid_view_rounded, size: 18)),
                ],
                selected: {_viewMode},
                onSelectionChanged: (Set<int> selected) {
                  setState(() => _viewMode = selected.first);
                },
              ),
            ],
          ),
        ),

        // Feedback panel
        if (_lastAddedIngredient != null && _currentAnalysis != null)
          StepFeedbackPanel(
            ingredient: _lastAddedIngredient!,
            analysis: _currentAnalysis!,
            onDismiss: () => setState(() => _lastAddedIngredient = null),
          ),

        // Grid
        Expanded(
          child: _viewMode == 0
              ? _buildSuggestionsView(context)
              : _buildBrowseView(context, searchResults, allIngredients),
        ),
      ],
    );
  }

  Widget _buildSuggestionsView(BuildContext context) {
    if (_loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestedIngredients.isEmpty) {
      return Center(
        child: Text(
          'No suggestions',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
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
              icon: const Icon(Icons.shuffle_rounded, size: 16),
              label: const Text('Shuffle'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _suggestedIngredients.length,
            itemBuilder: (context, index) {
              final ingredient = _suggestedIngredients[index];
              final isSelected = widget.selectedIngredients.contains(ingredient.name);
              return GestureDetector(
                onLongPress: () => _showIngredientDetail(context, ingredient),
                child: IngredientFeedbackCard(
                  ingredient: ingredient,
                  isSelected: isSelected,
                  onTap: () => _handleIngredientTap(ingredient),
                  showMoleculeInfo: true,
                ),
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
    List<Ingredient> allIngredients,
  ) {
    final ingredients = _searchController.text.isNotEmpty && searchResults.isNotEmpty
        ? searchResults
        : allIngredients;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final isSelected = widget.selectedIngredients.contains(ingredient.name);
        return IngredientFeedbackCard(
          ingredient: ingredient,
          isSelected: isSelected,
          onTap: () => _handleIngredientTap(ingredient),
          showMoleculeInfo: true,
        );
      },
    );
  }
}
