import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/ingredient.dart';
import '../../../../services/culinary_intelligence_service.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';

/// Step 2: Choose specific main ingredient
/// Matches app_voorstel_v2.md Scherm 2
class WizardChooseMainIngredientStep extends ConsumerStatefulWidget {
  final String category;

  const WizardChooseMainIngredientStep({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<WizardChooseMainIngredientStep> createState() =>
      _WizardChooseMainIngredientStepState();
}

class _WizardChooseMainIngredientStepState
    extends ConsumerState<WizardChooseMainIngredientStep> {
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final all = await CulinaryIntelligenceService.instance.getAllIngredients();
      
      // Filter by category - map category names to ingredient categories
      final filtered = all.where((ing) {
        final catName = ing.categoryName?.toLowerCase() ?? '';
        final categoryLower = widget.category.toLowerCase();
        
        // Map categories
        if (categoryLower == 'fish' || categoryLower == 'vis') {
          return catName.contains('fish') || catName.contains('vis') ||
              catName.contains('seafood');
        } else if (categoryLower == 'poultry' || categoryLower == 'gevogelte') {
          return catName.contains('poultry') || catName.contains('gevogelte') ||
              catName.contains('chicken') || catName.contains('kip');
        } else if (categoryLower == 'meat' || categoryLower == 'vlees') {
          return (catName.contains('meat') || catName.contains('vlees')) &&
              !catName.contains('poultry') && !catName.contains('gevogelte');
        } else if (categoryLower == 'vegetables' || categoryLower == 'groente') {
          return catName.contains('vegetable') || catName.contains('groente');
        } else if (categoryLower == 'legumes' || categoryLower == 'peulvruchten') {
          return catName.contains('legume') || catName.contains('peulvrucht') ||
              catName.contains('bean') || catName.contains('lentil');
        }
        return false;
      }).where((ing) => ing.canBeCarrier).toList();

      setState(() {
        _ingredients = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
          child: Row(
            children: [
              Text(
                widget.category.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Ingredients grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ingredients.isEmpty
                  ? Center(
                      child: Text(
                        'Geen ingrediënten gevonden',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return _IngredientCard(
                          ingredient: ingredient,
                          onTap: () => notifier.selectMainIngredient(ingredient),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;

  const _IngredientCard({
    required this.ingredient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get description from mouthfeel and flavor
    String getDescription() {
      if (ingredient.mouthfeel == MouthfeelCategory.coating) {
        return 'Filmend';
      } else if (ingredient.mouthfeel == MouthfeelCategory.astringent) {
        return 'Strak';
      } else if (ingredient.flavorProfile.umami > 0.5) {
        return 'Umami-rijk';
      } else if (ingredient.flavorProfile.sourness > 0.5) {
        return 'Zuur';
      }
      return 'Neutraal';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: AppColors.grey200,
                ),
                child: ingredient.imageUrl != null && ingredient.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: ingredient.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.grey200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grey200,
                            child: const Icon(Icons.image_not_supported, color: AppColors.grey400),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.grey200,
                        child: const Icon(Icons.image_not_supported, color: AppColors.grey400),
                      ),
              ),
            ),
            
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
