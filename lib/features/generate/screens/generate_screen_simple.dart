import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../services/ingredients_service.dart';
import '../../../services/credits_service.dart';
import '../../../services/generate_service.dart';
import '../../../services/recipe_service_simple.dart';
import '../providers/generate_simple_provider.dart';

class GenerateScreenSimple extends ConsumerStatefulWidget {
  const GenerateScreenSimple({super.key});

  @override
  ConsumerState<GenerateScreenSimple> createState() =>
      _GenerateScreenSimpleState();
}

class _GenerateScreenSimpleState extends ConsumerState<GenerateScreenSimple> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await IngredientsService.instance.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _categoriesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryDisplayName(Map<String, dynamic> c) {
    return (c['name_nl'] ?? c['name_en'] ?? c['name'] ?? '') as String;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generateSimpleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Text(
              'Create Recipe',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category selector
                  Text(
                    'Category',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'Alles',
                          selected: _selectedCategoryId == null,
                          onTap: () => setState(() => _selectedCategoryId = null),
                        ),
                        if (_categoriesLoaded)
                          ..._categories.map((c) {
                            final id = c['id'] as String?;
                            final name = _categoryDisplayName(c);
                            if (id == null || name.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _CategoryChip(
                                label: name,
                                selected: _selectedCategoryId == id,
                                onTap: () => setState(() => _selectedCategoryId = id),
                              ),
                            );
                          }),
                      ],
                    ),
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 20),
                  // Search
                  Text(
                    'Zoek ingrediënten',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'bijv. tomaat, kip, basilicum...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08, end: 0),
                ],
              ),
            ),
          ),
          FutureBuilder<List<SimpleIngredient>>(
            future: IngredientsService.instance.getIngredients(
              search: _search.isEmpty ? null : _search,
              categoryId: _selectedCategoryId,
            ),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }
              final list = snap.data!;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecteer ingrediënten',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 14),
                      list.isEmpty
                          ? _EmptyState(
                              hasSearch: _search.isNotEmpty,
                              hasCategory: _selectedCategoryId != null,
                            )
                          : _IngredientGrid(
                              ingredients: list,
                              state: state,
                              onAdd: (ing) =>
                                  ref.read(generateSimpleProvider.notifier).addIngredient(ing),
                              onRemove: (name) =>
                                  ref.read(generateSimpleProvider.notifier).removeIngredient(name),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 200)),
        ],
      ),
      bottomSheet: _BottomSheet(
        selected: state.selected,
        isGenerating: state.isGenerating,
        onRemove: (name) =>
            ref.read(generateSimpleProvider.notifier).removeIngredient(name),
        onGenerate: () => _handleGenerate(context),
      ),
    );
  }

  Future<void> _handleGenerate(BuildContext context) async {
    final selected = ref.read(generateSimpleProvider).selected;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecteer minimaal één ingrediënt')),
      );
      return;
    }

    final canGen = await CreditsService.instance.canGenerateRecipe();
    if (!canGen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geen credits meer. Koop er meer in Profiel.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notifier = ref.read(generateSimpleProvider.notifier);
    notifier.setGenerating(true);
    try {
      await CreditsService.instance.deductCredit();
      final recipe = await GenerateService.instance.generateRecipe(
        selected.map((i) => i.name).toList(),
      );
      final saved = await RecipeServiceSimple.instance.saveRecipe(recipe);
      if (context.mounted) {
        context.push('/recipe/${saved.id}', extra: saved);
      }
    } catch (e, st) {
      if (context.mounted) {
        final msg = e is PostgrestException ? (e.details ?? e.message) : '$e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout: $msg'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      debugPrint('Recipe save error: $e\n$st');
    } finally {
      notifier.setGenerating(false);
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final bool hasCategory;

  const _EmptyState({required this.hasSearch, required this.hasCategory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch || hasCategory
                ? 'Geen ingrediënten gevonden'
                : 'Geen ingrediënten in database',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch || hasCategory
                ? 'Probeer een andere zoekterm of categorie'
                : 'Voeg eerst ingrediënten toe aan de database',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IngredientGrid extends StatelessWidget {
  final List<SimpleIngredient> ingredients;
  final GenerateSimpleState state;
  final void Function(SimpleIngredient) onAdd;
  final void Function(String) onRemove;

  const _IngredientGrid({
    required this.ingredients,
    required this.state,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ingredients.length,
      itemBuilder: (ctx, i) {
        final ing = ingredients[i];
        final selected = state.selected.any((s) => s.name == ing.name);
        return _IngredientCard(
          ingredient: ing,
          selected: selected,
          onTap: () {
            if (selected) {
              onRemove(ing.name);
            } else {
              onAdd(ing);
            }
          },
        ).animate(delay: (i * 25).ms).fadeIn().slideY(begin: 0.08, end: 0);
      },
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final SimpleIngredient ingredient;
  final bool selected;
  final VoidCallback onTap;

  const _IngredientCard({
    required this.ingredient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (ingredient.imageUrl != null &&
                        ingredient.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: ingredient.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _buildPlaceholder(theme),
                      )
                    else
                      _buildPlaceholder(theme),
                    if (selected)
                      Container(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  ingredient.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.restaurant_rounded,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
}

/// Bottom sheet: selected ingredients (always visible) + Create Recipe button
class _BottomSheet extends StatelessWidget {
  final List<SimpleIngredient> selected;
  final bool isGenerating;
  final void Function(String) onRemove;
  final VoidCallback onGenerate;

  const _BottomSheet({
    required this.selected,
    required this.isGenerating,
    required this.onRemove,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Create Recipe button - primary CTA, always visible
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (selected.isNotEmpty && !isGenerating) ? onGenerate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          selected.isEmpty
                              ? 'Selecteer ingrediënten'
                              : 'Create Chef Recipe (${selected.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              // Selected ingredients - below Create Recipe button, always in view
              if (selected.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Geselecteerd (${selected.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selected.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final ing = selected[i];
                      return _SelectedChip(
                        ingredient: ing,
                        onRemove: () => onRemove(ing.name),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final SimpleIngredient ingredient;
  final VoidCallback onRemove;

  const _SelectedChip({
    required this.ingredient,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ingredient.imageUrl != null &&
                        ingredient.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ingredient.imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(theme),
                      )
                    : _placeholder(theme),
              ),
              const SizedBox(width: 10),
              Text(
                ingredient.name,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.close_rounded,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        width: 40,
        height: 40,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.restaurant_rounded,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
}
