import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../providers/generate_provider.dart';
import 'compact_header_bar.dart';
import 'compact_ingredient_grid.dart';
import 'wizard_preferences_step.dart';
import 'chef_analysis_sheet.dart';

/// Ultimate wizard with maximum space for ingredients and step-by-step feedback
class UltimateWizardScreen extends ConsumerStatefulWidget {
  const UltimateWizardScreen({super.key});

  @override
  ConsumerState<UltimateWizardScreen> createState() => _UltimateWizardScreenState();
}

class _UltimateWizardScreenState extends ConsumerState<UltimateWizardScreen> {
  Future<CompositionAnalysis>? _analysisFuture;
  String _analysisKey = '';
  bool _showPreferences = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(generateProvider);
      if (state.ingredients.isNotEmpty) {
        _ensureAnalysisFuture(state.ingredients);
      }
    });
  }

  void _ensureAnalysisFuture(List<String> ingredients) {
    if (ingredients.isEmpty) {
      _analysisKey = '';
      _analysisFuture = null;
      return;
    }

    // Include cooking methods in key for cache invalidation
    final state = ref.read(generateProvider);
    final cookingMethodsKey = state.cookingMethods.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    final key = '${ingredients.join('|')}|$cookingMethodsKey';
    
    if (key == _analysisKey && _analysisFuture != null) return;

    _analysisKey = key;
    _analysisFuture = CulinaryIntelligenceService.instance.analyzeComposition(
      ingredients,
      cookingMethods: state.cookingMethods.isNotEmpty ? state.cookingMethods : null,
    );
  }

  void _onIngredientAdded(String ingredient) {
    final notifier = ref.read(generateProvider.notifier);
    if (ref.read(generateProvider).ingredients.contains(ingredient)) {
      notifier.removeIngredient(ingredient);
    } else {
      notifier.addIngredient(ingredient);
    }
    
    final newIngredients = ref.read(generateProvider).ingredients;
    _ensureAnalysisFuture(newIngredients);
    setState(() {});
  }

  void _showAnalysisSheet() {
    if (_analysisFuture == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder<CompositionAnalysis>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 200);
          }
          return ChefAnalysisSheet(
            analysis: snapshot.data!,
            onAddIngredient: _onIngredientAdded,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateProvider);

    _ensureAnalysisFuture(state.ingredients);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showPreferences ? "Preferences" : "Compose Your Dish",
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_showPreferences) {
              setState(() => _showPreferences = false);
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            }
          },
        ),
        actions: [
          if (!_showPreferences)
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Scan ingredients',
              onPressed: () => context.push('/scan'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Compact header with score
          if (_analysisFuture != null)
            FutureBuilder<CompositionAnalysis>(
              future: _analysisFuture,
              builder: (context, snapshot) {
                return CompactHeaderBar(
                  selectedCount: state.ingredients.length,
                  score: snapshot.data?.overallScore,
                  onTap: state.ingredients.isNotEmpty ? _showAnalysisSheet : null,
                );
              },
            )
          else
            CompactHeaderBar(
              selectedCount: state.ingredients.length,
              onTap: null,
            ),

          // Main content
          Expanded(
            child: _showPreferences
                ? const WizardPreferencesStep()
                : CompactIngredientGrid(
                    selectedIngredients: state.ingredients,
                    onAdd: _onIngredientAdded,
                    analysisFuture: _analysisFuture,
                  ),
          ),

          // Continue button
          if (!_showPreferences && state.ingredients.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _showPreferences = true),
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
}
