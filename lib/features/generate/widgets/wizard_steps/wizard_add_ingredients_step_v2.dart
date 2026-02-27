import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/ingredient.dart';
import '../../../../shared/models/balans_analyse.dart' as balans;
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../../../services/culinary_intelligence_service.dart';

/// Step 5: Add ingredients - COMPACT REDESIGN
/// World-class UI with grid layout, shuffle, and maximum ingredient visibility
class WizardAddIngredientsStepV2 extends ConsumerStatefulWidget {
  const WizardAddIngredientsStepV2({super.key});

  @override
  ConsumerState<WizardAddIngredientsStepV2> createState() =>
      _WizardAddIngredientsStepV2State();
}

class _WizardAddIngredientsStepV2State
    extends ConsumerState<WizardAddIngredientsStepV2> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Ingredient> _filteredIngredients = [];
  List<Ingredient> _recommendedIngredients = [];
  List<Ingredient> _allIngredients = [];
  bool _isSearching = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload recommendations when state changes (e.g., after adding ingredient)
    final state = ref.read(smaakprofielWizardProvider);
    if (state.balanceAnalysis != null && !_isSearching) {
      _loadRecommendations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadAllIngredients();
    await _loadRecommendations();
  }

  Future<void> _loadAllIngredients() async {
    try {
      final all = await CulinaryIntelligenceService.instance.getAllIngredients();
      setState(() {
        _allIngredients = all;
      });
    } catch (e) {
      // Error loading
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredIngredients = [];
      });
      return;
    }

    _searchIngredients(query);
  }

  void _searchIngredients(String query) {
    final results = _allIngredients.where((ing) {
      return ing.name.toLowerCase().contains(query) ||
          (ing.description?.toLowerCase().contains(query) ?? false);
    }).take(50).toList();

    setState(() {
      _filteredIngredients = results;
    });
  }

  Future<void> _loadRecommendations() async {
    final state = ref.read(smaakprofielWizardProvider);
    
    // Reload all ingredients to get fresh data
    await _loadAllIngredients();
    
    if (state.balanceAnalysis == null) {
      // Show random ingredients if no balance analysis
      _shuffleRecommendations();
      return;
    }

    try {
      final currentNames = state.allIngredients.map((i) => i.name).toSet();

      // Get recommendations based on missing elements - GROUPED BY PRIORITY
      final recommendations = <Ingredient>[];
      final highPriority = <Ingredient>[];
      final mediumPriority = <Ingredient>[];
      final lowPriority = <Ingredient>[];

      for (final missing in state.balanceAnalysis!.ontbrekendeElementen) {
        final candidates = _allIngredients.where((ing) {
          if (currentNames.contains(ing.name)) return false;

          switch (missing.type) {
            case balans.OntbrekendElementType.strak:
              return ing.flavorProfile.sourness > 0.5 ||
                  ing.mouthfeel == MouthfeelCategory.astringent;
            case balans.OntbrekendElementType.filmend:
              return ing.mouthfeel == MouthfeelCategory.coating ||
                  ing.mouthfeel == MouthfeelCategory.rich ||
                  ing.moleculeType == MoleculeType.fat;
            case balans.OntbrekendElementType.fris:
              return ing.aromaCategories.contains('citrus') ||
                  ing.aromaCategories.contains('fresh') ||
                  ing.aromaCategories.contains('green');
            case balans.OntbrekendElementType.rijp:
              return ing.aromaCategories.contains('roasted') ||
                  ing.aromaCategories.contains('caramel') ||
                  ing.aromaCategories.contains('earthy');
            default:
              return false;
          }
        }).toList();

        // Group by priority
        for (final candidate in candidates) {
          if (highPriority.length < 6 && missing.priority == balans.MissingPriority.high) {
            highPriority.add(candidate);
          } else if (mediumPriority.length < 6 &&
              missing.priority == balans.MissingPriority.medium) {
            mediumPriority.add(candidate);
          } else if (lowPriority.length < 6 &&
              missing.priority == balans.MissingPriority.low) {
            lowPriority.add(candidate);
          }
        }
      }

      // Combine with randomization within each group
      recommendations.addAll(highPriority..shuffle(_random));
      recommendations.addAll(mediumPriority..shuffle(_random));
      recommendations.addAll(lowPriority..shuffle(_random));

      // Fill up to 12 if needed with random ingredients
      if (recommendations.length < 12) {
        final remaining = _allIngredients
            .where((ing) => !currentNames.contains(ing.name))
            .where((ing) => !recommendations.contains(ing))
            .toList()
          ..shuffle(_random);
        recommendations.addAll(remaining.take(12 - recommendations.length));
      }

      setState(() {
        _recommendedIngredients = recommendations.take(12).toList();
      });
    } catch (e) {
      _shuffleRecommendations();
    }
  }

  void _shuffleRecommendations() {
    final state = ref.read(smaakprofielWizardProvider);
    final currentNames = state.allIngredients.map((i) => i.name).toSet();
    final available = _allIngredients
        .where((ing) => !currentNames.contains(ing.name))
        .toList()
      ..shuffle(_random);

    setState(() {
      _recommendedIngredients = available.take(12).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    return Column(
      children: [
        // Compact search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: '🔍 Zoek ingrediënten...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocus.unfocus();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.grey300,
                  width: 1,
                ),
              ),
              filled: true,
              fillColor: AppColors.grey100,
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isSearching
              ? _buildSearchResults(context, notifier)
              : _buildRecommendations(context, notifier),
        ),
      ],
    );
  }

  Widget _buildRecommendations(
      BuildContext context, SmaakprofielWizardNotifier notifier) {
    return Column(
      children: [
        // Header with shuffle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Aanbevolen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _shuffleRecommendations();
                  _loadRecommendations(); // Reload based on current balance
                },
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text('Shuffle'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Compact grid - 3 columns, more visible
        Expanded(
          child: _recommendedIngredients.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75, // Taller cards for images
                  ),
                  itemCount: _recommendedIngredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = _recommendedIngredients[index];
                    return _CompactIngredientCard(
                      ingredient: ingredient,
                      onTap: () => notifier.previewIngredient(ingredient),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
      BuildContext context, SmaakprofielWizardNotifier notifier) {
    if (_filteredIngredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Geen resultaten',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index];
        return _CompactIngredientCard(
          ingredient: ingredient,
          onTap: () => notifier.previewIngredient(ingredient),
        );
      },
    );
  }
}

class _CompactIngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;

  const _CompactIngredientCard({
    required this.ingredient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: ingredient.imageUrl != null &&
                          ingredient.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ingredient.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppColors.grey200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grey200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: AppColors.grey400,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.grey200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 24,
                            color: AppColors.grey400,
                          ),
                        ),
                ),
              ),
              // Name
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Center(
                    child: Text(
                      ingredient.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
}
