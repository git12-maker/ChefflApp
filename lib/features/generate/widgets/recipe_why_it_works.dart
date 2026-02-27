import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/models/recipe.dart';
import '../../../services/culinary_intelligence_service.dart';

/// Section explaining why the recipe works based on culinary science
/// Uses actual ingredient analysis with new data (mouthfeel, aroma_categories, texture_categories)
class RecipeWhyItWorks extends ConsumerStatefulWidget {
  const RecipeWhyItWorks({
    super.key,
    required this.recipe,
    this.ingredients,
  });

  final Recipe recipe;
  final List<String>? ingredients;

  @override
  ConsumerState<RecipeWhyItWorks> createState() => _RecipeWhyItWorksState();
}

class _RecipeWhyItWorksState extends ConsumerState<RecipeWhyItWorks> {
  Future<CompositionAnalysis>? _analysisFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  @override
  void didUpdateWidget(RecipeWhyItWorks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe != widget.recipe || oldWidget.ingredients != widget.ingredients) {
      _loadAnalysis();
    }
  }

  void _loadAnalysis() {
    final ingredientNames = widget.ingredients ?? 
        widget.recipe.ingredients.map((i) => i.name).toList();
    if (ingredientNames.isNotEmpty) {
      setState(() {
        _analysisFuture = CulinaryIntelligenceService.instance.analyzeComposition(ingredientNames);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Why This Works',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<CompositionAnalysis>(
            future: _analysisFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData) {
                return Text(
                  _generateFallbackExplanation(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                );
              }
              
              final analysis = snapshot.data!;
              return Text(
                _generateExplanation(analysis),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _generateExplanation(CompositionAnalysis analysis) {
    final explanations = <String>[];
    
    // Analyze flavor balance using actual data
    explanations.add(_analyzeFlavorBalance(analysis));
    
    // Analyze texture using texture_categories and mouthfeel
    explanations.add(_analyzeTexture(analysis));
    
    // Analyze aroma using aroma_categories
    explanations.add(_analyzeAroma(analysis));
    
    // Analyze cooking method
    explanations.add(_analyzeCookingMethod());
    
    return explanations.where((e) => e.isNotEmpty).join('\n\n');
  }

  String _analyzeFlavorBalance(CompositionAnalysis analysis) {
    final profile = analysis.flavorProfile;
    final parts = <String>[];
    
    if (profile.umami >= 0.3) {
      parts.add('The umami-rich ingredients (${profile.umami.toStringAsFixed(1)}) create deep, satisfying flavors');
    }
    if (profile.sourness >= 0.2) {
      parts.add('acidity (${profile.sourness.toStringAsFixed(1)}) adds brightness and cuts through richness');
    }
    if (profile.sweetness >= 0.2) {
      parts.add('subtle sweetness (${profile.sweetness.toStringAsFixed(1)}) balances the savory elements');
    }
    
    if (parts.isEmpty) {
      return 'This recipe achieves balance through the five basic tastes: sweet, salty, sour, bitter, and umami. Each ingredient contributes to this harmony, creating depth and satisfaction.';
    }
    
    return parts.join(', ') + '.';
  }

  String _analyzeTexture(CompositionAnalysis analysis) {
    final textureAnalysis = analysis.textureVariety;
    final parts = <String>[];
    
    if (textureAnalysis.hasCrispyCreamy) {
      parts.add('contrasting crispy with creamy textures');
    }
    
    final textures = textureAnalysis.textures;
    if (textures.length >= 3) {
      final textureNames = textures.map((t) => t.name).join(', ');
      parts.add('textural variety ($textureNames)');
    }
    
    final mouthfeels = textureAnalysis.mouthfeels.toSet();
    if (mouthfeels.length >= 2) {
      final mouthfeelNames = mouthfeels.map((m) => m.name).join(' and ');
      parts.add('contrasting mouthfeels ($mouthfeelNames)');
    }
    
    if (parts.isEmpty) {
      return 'The combination of ingredients provides textural variety, creating an interesting mouthfeel that keeps each bite engaging.';
    }
    
    return 'The dish offers ' + parts.join(', ') + ', creating an engaging mouthfeel experience.';
  }

  String _analyzeAroma(CompositionAnalysis analysis) {
    // Collect all aroma categories from ingredients
    final allAromas = <String>{};
    for (final ingredient in analysis.ingredients) {
      allAromas.addAll(ingredient.aromaCategories);
    }
    
    if (allAromas.isEmpty) {
      return '';
    }
    
    final aromaList = allAromas.toList();
    if (aromaList.length == 1) {
      return 'The ${aromaList.first} aromas create a focused, harmonious scent profile.';
    } else {
      return 'The combination of ${aromaList.join(', ')} aromas creates a complex, layered scent that enhances the overall flavor experience.';
    }
  }
  
  String _generateFallbackExplanation() {
    return 'This recipe works through careful balance of flavors, textures, and cooking methods. Each ingredient contributes to a harmonious whole.';
  }

  String _analyzeCookingMethod() {
    if (widget.recipe.instructions.isEmpty) return '';
    
    final methods = <String>[];
    for (final step in widget.recipe.instructions) {
      final lower = step.toLowerCase();
      if (lower.contains('roast') || lower.contains('bake')) {
        methods.add('roasting');
      } else if (lower.contains('grill') || lower.contains('sear')) {
        methods.add('grilling');
      } else if (lower.contains('braise') || lower.contains('stew')) {
        methods.add('braising');
      } else if (lower.contains('sauté') || lower.contains('pan')) {
        methods.add('sautéing');
      }
    }
    
    if (methods.isEmpty) return '';
    
    final uniqueMethods = methods.toSet().toList();
    if (uniqueMethods.contains('roasting')) {
      return 'The roasting method develops complex flavors through the Maillard reaction, creating rich, savory notes that enhance the natural sweetness of the ingredients.';
    } else if (uniqueMethods.contains('grilling')) {
      return 'Grilling adds smoky, charred flavors that complement the ingredients, creating depth through caramelization.';
    } else if (uniqueMethods.contains('braising')) {
      return 'Braising gently breaks down tough fibers while concentrating flavors, resulting in tender, deeply flavored results.';
    }
    
    return 'The cooking methods used enhance the natural flavors of the ingredients, creating a harmonious final dish.';
  }
}
