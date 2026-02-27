import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/ingredient.dart';
import '../../../../shared/models/balans_analyse.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../../../services/culinary_intelligence_service.dart';
import '../../providers/ingredient_provider.dart';

/// Step 5: Add ingredients
/// Matches app_voorstel_v2.md Scherm 5
class WizardAddIngredientsStep extends ConsumerStatefulWidget {
  const WizardAddIngredientsStep({super.key});

  @override
  ConsumerState<WizardAddIngredientsStep> createState() =>
      _WizardAddIngredientsStepState();
}

class _WizardAddIngredientsStepState
    extends ConsumerState<WizardAddIngredientsStep> {
  final TextEditingController _searchController = TextEditingController();
  List<Ingredient> _filteredIngredients = [];
  List<Ingredient> _recommendedIngredients = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _searchIngredients(String query) async {
    try {
      final results = await CulinaryIntelligenceService.instance
          .searchIngredients(query);
      setState(() {
        _filteredIngredients = results;
      });
    } catch (e) {
      setState(() {
        _filteredIngredients = [];
      });
    }
  }

  Future<void> _loadRecommendations() async {
    final state = ref.read(smaakprofielWizardProvider);
    if (state.balanceAnalysis == null) return;

    try {
      final all = await CulinaryIntelligenceService.instance.getAllIngredients();
      final currentNames = state.allIngredients.map((i) => i.name).toSet();

      // Get recommendations based on missing elements
      final recommendations = <Ingredient>[];
      for (final missing in state.balanceAnalysis!.ontbrekendeElementen) {
        final candidates = all.where((ing) {
          if (currentNames.contains(ing.name)) return false;

          switch (missing.type) {
            case OntbrekendElementType.strak:
              return ing.flavorProfile.sourness > 0.5 ||
                  ing.mouthfeel == MouthfeelCategory.astringent;
            case OntbrekendElementType.filmend:
              return ing.mouthfeel == MouthfeelCategory.coating ||
                  ing.mouthfeel == MouthfeelCategory.rich ||
                  ing.moleculeType == MoleculeType.fat;
            case OntbrekendElementType.fris:
              return ing.aromaCategories.contains('citrus') ||
                  ing.aromaCategories.contains('fresh') ||
                  ing.aromaCategories.contains('green');
            case OntbrekendElementType.rijp:
              return ing.aromaCategories.contains('roasted') ||
                  ing.aromaCategories.contains('caramel') ||
                  ing.aromaCategories.contains('earthy');
            default:
              return false;
          }
        }).take(3).toList();

        recommendations.addAll(candidates);
      }

      setState(() {
        _recommendedIngredients = recommendations.take(6).toList();
      });
    } catch (e) {
      // Error loading recommendations
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOEVOEGEN AAN GERECHT',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '🔍 Zoeken...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Content
        Expanded(
          child: _isSearching
              ? _buildSearchResults(context, notifier)
              : _buildRecommendations(context, notifier),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context, SmaakprofielWizardNotifier notifier) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recommendedIngredients.isNotEmpty) ...[
            Text(
              'AANBEVOLEN VOOR BALANS:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 16),
            ..._recommendedIngredients.map((ing) => _RecommendationCard(
                  ingredient: ing,
                  onTap: () => notifier.previewIngredient(ing),
                )),
            const SizedBox(height: 32),
          ],
          
          Text(
            'ALLE CATEGORIEËN:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(label: 'Groenten'),
              _CategoryChip(label: 'Kruiden'),
              _CategoryChip(label: 'Zuren'),
              _CategoryChip(label: 'Vetten'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, SmaakprofielWizardNotifier notifier) {
    if (_filteredIngredients.isEmpty) {
      return Center(
        child: Text(
          'Geen resultaten gevonden',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index];
        return _IngredientListItem(
          ingredient: ingredient,
          onTap: () => notifier.previewIngredient(ingredient),
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.ingredient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji or image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: ingredient.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.image_not_supported, size: 24, color: AppColors.grey400),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.image_not_supported, size: 24, color: AppColors.grey400),
                      ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Voegt frisheid toe',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientListItem extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;

  const _IngredientListItem({
    required this.ingredient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: ingredient.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.grey200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.grey200,
                    child: const Icon(Icons.image_not_supported, size: 24, color: AppColors.grey400),
                  ),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                color: AppColors.grey200,
                child: const Icon(Icons.image_not_supported, size: 24, color: AppColors.grey400),
              ),
        title: Text(ingredient.name),
        subtitle: ingredient.description != null
            ? Text(
                ingredient.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.primary),
    );
  }
}
