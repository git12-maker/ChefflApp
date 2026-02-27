import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/ingredient_provider.dart';

/// Current step in the wizard: selecting the next ingredient
class WizardIngredientStep extends ConsumerStatefulWidget {
  const WizardIngredientStep({
    super.key,
    required this.selectedIngredients,
    required this.onAdd,
    this.analysisFuture,
    this.onContinue,
  });

  final List<String> selectedIngredients;
  final ValueChanged<String> onAdd;
  final Future<CompositionAnalysis>? analysisFuture;
  final VoidCallback? onContinue;

  @override
  ConsumerState<WizardIngredientStep> createState() => _WizardIngredientStepState();
}

class _WizardIngredientStepState extends ConsumerState<WizardIngredientStep> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showBrowse = false;
  List<IngredientSuggestion> _currentSuggestions = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(WizardIngredientStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIngredients.length != widget.selectedIngredients.length ||
        oldWidget.analysisFuture != widget.analysisFuture) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (widget.selectedIngredients.isEmpty) {
      // For first ingredient, show ALL carriers
      setState(() {
        _loadingSuggestions = true;
      });
      try {
        final allIngredients = await CulinaryIntelligenceService.instance.getAllIngredients();
        // Show ALL carriers, not just a limited subset
        final carriers = allIngredients
            .where((i) => i.canBeCarrier)
            .map((i) => IngredientSuggestion(
                  ingredient: i,
                  reason: 'Great starting point for your dish',
                  missingElement: ElementType.carrier,
                  priority: MissingPriority.high,
                ))
            .toList();
        setState(() {
          _currentSuggestions = carriers;
          _loadingSuggestions = false;
        });
      } catch (e) {
        setState(() {
          _loadingSuggestions = false;
        });
      }
      return;
    }

    // Load suggestions from analysis
    if (widget.analysisFuture != null) {
      setState(() {
        _loadingSuggestions = true;
      });
      try {
        final analysis = await widget.analysisFuture;
        if (analysis != null && mounted) {
          setState(() {
            _currentSuggestions = analysis.suggestions;
            _loadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingSuggestions = false;
          });
        }
      }
    }
  }

  void _shuffleSuggestions() {
    if (_currentSuggestions.isEmpty) return;
    final rnd = Random();
    final shuffled = List<IngredientSuggestion>.from(_currentSuggestions)..shuffle(rnd);
    setState(() {
      _currentSuggestions = shuffled;
    });
  }

  void _addIngredient(String name) {
    widget.onAdd(name);
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _showBrowse = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchResults = ref.watch(ingredientProvider).searchResults;

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Step header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedIngredients.isEmpty
                      ? 'Step 1: Choose your main ingredient'
                      : 'Step ${widget.selectedIngredients.length + 1}: What else?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectedIngredients.isEmpty
                      ? 'Start with a protein, starch, or featured vegetable'
                      : 'Add ingredients that complement what you have',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for an ingredient...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(ingredientProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
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
                  _addIngredient(value.trim());
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Toggle between suggestions and browse
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Suggestions'),
                        icon: Icon(Icons.lightbulb_outline_rounded),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Browse'),
                        icon: Icon(Icons.list_rounded),
                      ),
                    ],
                    selected: {_showBrowse},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _showBrowse = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content: suggestions or browse
          Expanded(
            child: _showBrowse
                ? _buildBrowseView(context, searchResults)
                : _buildSuggestionsView(context),
          ),

          // Continue button (only show if ingredients are selected)
          if (widget.selectedIngredients.isNotEmpty && widget.onContinue != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue to Preferences'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentSuggestions.isEmpty) {
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Random button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _shuffleSuggestions,
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Shuffle'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Suggestions grid
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text(
                'Chef\'s Recommendations',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              ..._currentSuggestions.map((suggestion) {
                return _buildSuggestionCard(context, suggestion);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(BuildContext context, IngredientSuggestion suggestion) {
    final theme = Theme.of(context);
    final priority = suggestion.priority;
    final priorityColor = priority == MissingPriority.high
        ? AppColors.error
        : priority == MissingPriority.medium
            ? AppColors.warning
            : AppColors.info;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _addIngredient(suggestion.ingredient.name),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.ingredient.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseView(BuildContext context, List<Ingredient> searchResults) {
    final theme = Theme.of(context);
    final categorized = ref.watch(ingredientProvider).categorizedIngredients;
    final isLoading = ref.watch(ingredientProvider).isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show search results if searching
    if (_searchController.text.isNotEmpty && searchResults.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Search Results',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...searchResults.map((ingredient) {
            return ListTile(
              title: Text(
                ingredient.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: ingredient.description != null
                  ? Text(
                      ingredient.description!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    )
                  : null,
              trailing: const Icon(Icons.add_rounded),
              onTap: () => _addIngredient(ingredient.name),
            );
          }),
        ],
      );
    }

    // Show categories
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Browse by Category',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...categorized.entries.map((entry) {
          return ExpansionTile(
            title: Text(
              entry.key,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text('${entry.value.length} ingredients'),
            children: entry.value.map((ingredient) {
              return ListTile(
                title: Text(
                  ingredient.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                trailing: const Icon(Icons.add_rounded),
                onTap: () => _addIngredient(ingredient.name),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
