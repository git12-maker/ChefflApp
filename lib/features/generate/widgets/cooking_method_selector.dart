import 'package:flutter/material.dart';
import '../../../services/cooking_methods_service.dart';
import '../../../shared/models/ingredient.dart';

/// Widget for selecting cooking method for an ingredient
class CookingMethodSelector extends StatefulWidget {
  const CookingMethodSelector({
    super.key,
    required this.ingredient,
    this.selectedMethod,
    required this.onMethodSelected,
  });

  final Ingredient ingredient;
  final String? selectedMethod;
  final ValueChanged<String> onMethodSelected;

  @override
  State<CookingMethodSelector> createState() => _CookingMethodSelectorState();
}

class _CookingMethodSelectorState extends State<CookingMethodSelector> {
  List<CookingMethod> _availableMethods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _loading = true);
    try {
      final methods = await CookingMethodsService.instance.getCookingMethodsForIngredient(
        widget.ingredient.id,
      );
      
      // If no specific methods, show common methods
      if (methods.isEmpty) {
        // Fallback: show common methods based on ingredient type
        _availableMethods = _getCommonMethodsForIngredient();
      } else {
        _availableMethods = methods;
      }
      
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _availableMethods = _getCommonMethodsForIngredient();
        });
      }
    }
  }

  List<CookingMethod> _getCommonMethodsForIngredient() {
    // Return common methods based on molecule type
    // This is a fallback when no specific data exists
    final commonMethods = <String>['Raw', 'Roasting', 'Pan-frying', 'Steaming', 'Boiling'];
    return commonMethods.map((name) => CookingMethod(
      id: '',
      nameEn: name,
      heatType: name == 'Raw' ? 'none' : 'dry',
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableMethods.isEmpty) {
      return Text(
        'No cooking methods available',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableMethods.map((method) {
        final isSelected = widget.selectedMethod == method.nameEn;
        return FilterChip(
          label: Text(method.nameEn),
          selected: isSelected,
          onSelected: (_) => widget.onMethodSelected(method.nameEn),
        );
      }).toList(),
    );
  }
}
