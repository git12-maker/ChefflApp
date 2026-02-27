import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../providers/generate_provider.dart';
import 'wizard_progress_bar.dart';
import 'wizard_analysis_summary.dart';
import 'wizard_ingredient_step.dart';
import 'wizard_preferences_step.dart';

/// Wizard-style ingredient selection screen
/// Guides user step-by-step through ingredient selection
class IngredientWizardScreen extends ConsumerStatefulWidget {
  const IngredientWizardScreen({super.key});

  @override
  ConsumerState<IngredientWizardScreen> createState() => _IngredientWizardScreenState();
}

class _IngredientWizardScreenState extends ConsumerState<IngredientWizardScreen> {
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
              // Go back to ingredient selection
              setState(() {
                _showPreferences = false;
              });
            } else {
              // Go back to previous screen
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
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar showing selected ingredients
            WizardProgressBar(
              ingredients: state.ingredients,
              onRemove: _onIngredientRemoved,
            ),
            
            // Analysis summary (always visible)
            if (_analysisFuture != null)
              FutureBuilder<CompositionAnalysis>(
                future: _analysisFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return WizardAnalysisSummary(
                    analysis: snapshot.data!,
                    onAddIngredient: _onIngredientAdded,
                  );
                },
              ),
            
            // Current step: ingredient selection or preferences
            Expanded(
              child: _showPreferences
                  ? const WizardPreferencesStep()
                  : WizardIngredientStep(
                      selectedIngredients: state.ingredients,
                      onAdd: _onIngredientAdded,
                      analysisFuture: _analysisFuture,
                      onContinue: () {
                        setState(() {
                          _showPreferences = true;
                        });
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
