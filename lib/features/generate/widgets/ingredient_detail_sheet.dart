import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/cooking_methods_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/generate_provider.dart';
import 'cooking_method_selector.dart';
import 'cooking_effect_preview.dart';

/// Bottom sheet showing detailed ingredient information with cooking methods
class IngredientDetailSheet extends ConsumerStatefulWidget {
  const IngredientDetailSheet({
    super.key,
    required this.ingredient,
    this.onCookingMethodSelected,
  });

  final Ingredient ingredient;
  final ValueChanged<String>? onCookingMethodSelected;

  @override
  ConsumerState<IngredientDetailSheet> createState() => _IngredientDetailSheetState();
}

class _IngredientDetailSheetState extends ConsumerState<IngredientDetailSheet> {
  String? _selectedCookingMethod;
  CookingEffect? _cookingEffect;
  bool _loadingEffect = false;

  @override
  void initState() {
    super.initState();
    // Check if cooking method is already selected in state
    final state = ref.read(generateProvider);
    final selectedMethod = state.cookingMethods[widget.ingredient.name];
    if (selectedMethod != null && selectedMethod.isNotEmpty) {
      _selectedCookingMethod = selectedMethod;
      _loadCookingEffect(selectedMethod);
    } else {
      _loadOptimalMethod();
    }
  }

  Future<void> _loadOptimalMethod() async {
    final optimal = await CookingMethodsService.instance.getOptimalCookingMethod(widget.ingredient.id);
    if (optimal != null && mounted) {
      setState(() => _selectedCookingMethod = optimal.nameEn);
      _loadCookingEffect(optimal.nameEn);
    }
  }

  Future<void> _loadCookingEffect(String methodName) async {
    setState(() => _loadingEffect = true);
    try {
      final effect = await CookingMethodsService.instance.getCookingEffect(
        widget.ingredient.id,
        methodName,
      );
      if (mounted) {
        setState(() {
          _cookingEffect = effect;
          _loadingEffect = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingEffect = false);
      }
    }
  }

  void _handleMethodSelected(String methodName) {
    setState(() => _selectedCookingMethod = methodName);
    _loadCookingEffect(methodName);
    widget.onCookingMethodSelected?.call(methodName);
    
    // Update state via provider
    ref.read(generateProvider.notifier).setCookingMethod(
      widget.ingredient.name,
      methodName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ingredient.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.ingredient.categoryName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.ingredient.categoryName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Molecule type
                      _buildSection(
                        context,
                        'Molecule Type',
                        _buildMoleculeInfo(context),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Cooking method selector
                      _buildSection(
                        context,
                        'Cooking Method',
                        CookingMethodSelector(
                          ingredient: widget.ingredient,
                          selectedMethod: _selectedCookingMethod,
                          onMethodSelected: _handleMethodSelected,
                        ),
                      ),
                      
                      // Cooking effect preview
                      if (_selectedCookingMethod != null) ...[
                        const SizedBox(height: 16),
                        if (_loadingEffect)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_cookingEffect != null)
                          CookingEffectPreview(
                            effect: _cookingEffect!,
                            baseIngredient: widget.ingredient,
                          ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Flavor profile
                      if (widget.ingredient.flavorProfile.umami > 0 ||
                          widget.ingredient.flavorProfile.sourness > 0 ||
                          widget.ingredient.flavorProfile.sweetness > 0)
                        _buildSection(
                          context,
                          'Flavor Profile',
                          _buildFlavorProfile(context),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Aroma info
                      if (widget.ingredient.aromaCategories.isNotEmpty) ...[
                        _buildSection(
                          context,
                          'Aroma',
                          _buildAromaInfo(context),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Texture info
                      if (widget.ingredient.textures.isNotEmpty) ...[
                        _buildSection(
                          context,
                          'Texture',
                          _buildTextureInfo(context),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Description
                      if (widget.ingredient.description != null) ...[
                        _buildSection(
                          context,
                          'Description',
                          Text(
                            widget.ingredient.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildMoleculeInfo(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    Color color;
    String description;
    
    switch (widget.ingredient.moleculeType) {
      case MoleculeType.water:
        label = '💧 Water';
        color = Colors.blue;
        description = 'High water content - adds moisture and freshness';
        break;
      case MoleculeType.fat:
        label = '🧈 Fat';
        color = Colors.amber;
        description = 'High fat content - carries flavors, adds richness';
        break;
      case MoleculeType.carbohydrate:
        label = '🌾 Carbohydrate';
        color = Colors.orange;
        description = 'Starch and sugars - provides energy and structure';
        break;
      case MoleculeType.protein:
        label = '🥩 Protein';
        color = Colors.red;
        description = 'High protein - provides satisfaction and umami';
        break;
      default:
        label = 'Mixed';
        color = Colors.grey;
        description = 'Balanced composition';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlavorProfile(BuildContext context) {
    final profile = widget.ingredient.flavorProfile;
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (profile.umami > 0.1)
          _buildFlavorChip(context, 'Umami', profile.umami),
        if (profile.sourness > 0.1)
          _buildFlavorChip(context, 'Sour', profile.sourness),
        if (profile.sweetness > 0.1)
          _buildFlavorChip(context, 'Sweet', profile.sweetness),
        if (profile.saltiness > 0.1)
          _buildFlavorChip(context, 'Salty', profile.saltiness),
        if (profile.bitterness > 0.1)
          _buildFlavorChip(context, 'Bitter', profile.bitterness),
      ],
    );
  }

  Widget _buildFlavorChip(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    final intensity = (value * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$intensity%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAromaInfo(BuildContext context) {
    final theme = Theme.of(context);
    final categories = widget.ingredient.aromaCategories;
    final intensity = (widget.ingredient.aromaIntensity * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: categories.map((category) {
            return Chip(
              label: Text(
                category,
                style: theme.textTheme.labelSmall,
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.water_drop_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Intensity: $intensity%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextureInfo(BuildContext context) {
    final theme = Theme.of(context);
    final textures = widget.ingredient.textures;
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: textures.map((texture) {
        return Chip(
          label: Text(
            texture.name,
            style: theme.textTheme.labelSmall,
          ),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
