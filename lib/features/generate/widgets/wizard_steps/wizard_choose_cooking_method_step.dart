import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/ingredient.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../../../services/cooking_methods_service.dart';

/// Step 3: Choose cooking method
/// Matches app_voorstel_v2.md Scherm 3
class WizardChooseCookingMethodStep extends ConsumerStatefulWidget {
  final Ingredient ingredient;

  const WizardChooseCookingMethodStep({
    super.key,
    required this.ingredient,
  });

  @override
  ConsumerState<WizardChooseCookingMethodStep> createState() =>
      _WizardChooseCookingMethodStepState();
}

class _WizardChooseCookingMethodStepState
    extends ConsumerState<WizardChooseCookingMethodStep> {
  List<CookingMethod> _methods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCookingMethods();
  }

  Future<void> _loadCookingMethods() async {
    try {
      final all = await CookingMethodsService.instance.getAllCookingMethods();
      
      // Filter common methods
      final commonMethods = all.where((m) {
        final name = m.nameEn.toLowerCase();
        return name.contains('steam') ||
            name.contains('bake') ||
            name.contains('pan-fry') ||
            name.contains('fry') ||
            name.contains('poach') ||
            name.contains('grill') ||
            name.contains('roast') ||
            name.contains('raw');
      }).toList();

      setState(() {
        _methods = commonMethods;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.ingredient.name.toUpperCase()} BEREIDEN',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hoe wil je de ${widget.ingredient.name.toLowerCase()} bereiden?',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Methods grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _methods.length,
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    return _MethodCard(
                      method: method,
                      onTap: () async {
                        try {
                          await notifier.selectCookingMethod(method.nameEn);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Fout: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final CookingMethod method;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.onTap,
  });

  String _getMethodName() {
    final name = method.nameEn.toLowerCase();
    if (name.contains('steam')) return 'Stomen';
    if (name.contains('bake') || name.contains('roast')) return 'Bakken';
    if (name.contains('pan-fry') || name.contains('fry')) return 'Bakken';
    if (name.contains('poach')) return 'Pocheren';
    if (name.contains('grill')) return 'Grilleren';
    if (name.contains('raw')) return 'Rauw';
    return method.nameNl ?? method.nameEn;
  }

  String _getDescription() {
    final name = method.nameEn.toLowerCase();
    if (name.contains('steam')) return 'Zacht, Fris';
    if (name.contains('bake') || name.contains('roast')) return 'Krokant, Rijp';
    if (name.contains('pan-fry') || name.contains('fry')) return 'Krokant, Rijp';
    if (name.contains('poach')) return 'Mals, Mild';
    if (name.contains('grill')) return 'Intens, Rokerig';
    if (name.contains('raw')) return 'Vers, Fris';
    return 'Bereiden';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getMethodName(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getDescription(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
