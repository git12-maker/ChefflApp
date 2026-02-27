import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../providers/generate_provider.dart';
import 'minimal_progress_indicator.dart';
import 'ingredient_selection_grid.dart';
import 'wizard_preferences_step.dart';
import 'chef_analysis_sheet.dart';

/// New minimalist wizard with maximum space for ingredient selection
class NewIngredientWizardScreen extends ConsumerStatefulWidget {
  const NewIngredientWizardScreen({super.key});

  @override
  ConsumerState<NewIngredientWizardScreen> createState() => _NewIngredientWizardScreenState();
}

class _NewIngredientWizardScreenState extends ConsumerState<NewIngredientWizardScreen> {
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

    final key = ingredients.join('|');
    if (key == _analysisKey && _analysisFuture != null) return;

    _analysisKey = key;
    _analysisFuture = CulinaryIntelligenceService.instance.analyzeComposition(ingredients);
  }

  void _onIngredientAdded(String ingredient) {
    final notifier = ref.read(generateProvider.notifier);
    notifier.addIngredient(ingredient);
    
    final newIngredients = [...ref.read(generateProvider).ingredients, ingredient];
    _ensureAnalysisFuture(newIngredients);
    setState(() {});
  }

  void _onIngredientRemoved(String ingredient) {
    final notifier = ref.read(generateProvider.notifier);
    notifier.removeIngredient(ingredient);
    
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
    final theme = Theme.of(context);

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
          if (!_showPreferences) ...[
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Scan ingredients',
              onPressed: () => context.push('/scan'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Minimal progress indicator
          if (_analysisFuture != null)
            FutureBuilder<CompositionAnalysis>(
              future: _analysisFuture,
              builder: (context, snapshot) {
                return MinimalProgressIndicator(
                  selectedCount: state.ingredients.length,
                  score: snapshot.data?.overallScore,
                  onTap: state.ingredients.isNotEmpty ? _showAnalysisSheet : null,
                );
              },
            )
          else
            MinimalProgressIndicator(
              selectedCount: state.ingredients.length,
              onTap: null,
            ),

          // Main content: ingredient selection or preferences
          Expanded(
            child: _showPreferences
                ? const WizardPreferencesStep()
                : IngredientSelectionGrid(
                    selectedIngredients: state.ingredients,
                    onAdd: (name) {
                      if (state.ingredients.contains(name)) {
                        _onIngredientRemoved(name);
                      } else {
                        _onIngredientAdded(name);
                      }
                    },
                    analysisFuture: _analysisFuture,
                  ),
          ),

          // Continue button (only in ingredient selection)
          if (!_showPreferences && state.ingredients.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
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
