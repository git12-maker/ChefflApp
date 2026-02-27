import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';
import '../../../shared/models/ingredient.dart';
import '../providers/ingredient_provider.dart';

class IngredientPickerSheet extends ConsumerStatefulWidget {
  const IngredientPickerSheet({
    super.key,
    required this.selectedIngredients,
    required this.onAdd,
    this.initialTabIndex = 0,
  });

  final List<String> selectedIngredients;
  final void Function(String ingredientName) onAdd;
  final int initialTabIndex; // 0 = Guided, 1 = Browse

  @override
  ConsumerState<IngredientPickerSheet> createState() =>
      _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends ConsumerState<IngredientPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _selectedCategory = 'All';
  CompositionAnalysis? _analysis;
  List<IngredientSuggestion> _guided = const [];
  bool _loadingAnalysis = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );

    _searchController.addListener(_onSearchChanged);
    _refreshAnalysis();
    
    // Refresh ingredients to get latest images from database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ingredientProvider.notifier).refresh();
      }
      if (mounted && _tabController.index == 1) {
        _searchFocus.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant IngredientPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameList(oldWidget.selectedIngredients, widget.selectedIngredients)) {
      _refreshAnalysis();
    }
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      ref.read(ingredientProvider.notifier).clearSearch();
    } else {
      ref.read(ingredientProvider.notifier).search(q);
    }
  }

  Future<void> _refreshAnalysis() async {
    if (widget.selectedIngredients.isEmpty) {
      setState(() {
        _analysis = null;
        _guided = const [];
        _loadingAnalysis = false;
      });
      return;
    }

    setState(() => _loadingAnalysis = true);
    try {
      final analysis = await CulinaryIntelligenceService.instance
          .analyzeComposition(widget.selectedIngredients);
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _guided = _pickGuidedSuggestions(analysis.suggestions);
        _loadingAnalysis = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAnalysis = false);
    }
  }

  List<IngredientSuggestion> _pickGuidedSuggestions(
    List<IngredientSuggestion> all,
  ) {
    if (all.isEmpty) return const [];
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);

    // Return all suggestions, shuffled within each priority group
    // This maintains priority ordering but randomizes within each group
    final high = all.where((s) => s.priority == MissingPriority.high).toList()
      ..shuffle(rnd);
    final med = all.where((s) => s.priority == MissingPriority.medium).toList()
      ..shuffle(rnd);
    final low = all.where((s) => s.priority == MissingPriority.low).toList()
      ..shuffle(rnd);

    // Return all suggestions, grouped by priority (high first)
    return [...high, ...med, ...low];
  }

  void _reshuffleGuided() {
    final analysis = _analysis;
    if (analysis == null) return;
    setState(() => _guided = _pickGuidedSuggestions(analysis.suggestions));
  }

  void _add(String name) {
    widget.onAdd(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Added $name')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredientState = ref.watch(ingredientProvider);

    final height = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: height,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add ingredients',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Guided'),
                Tab(text: 'Browse'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGuided(context, ingredientState),
                _buildBrowse(context, ingredientState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuided(
    BuildContext context,
    IngredientSelectionState ingredientState,
  ) {
    final theme = Theme.of(context);

    if (widget.selectedIngredients.isEmpty) {
      return _buildCarrierStart(context, ingredientState);
    }

    if (_loadingAnalysis) {
      return const Center(child: CircularProgressIndicator());
    }

    final analysis = _analysis;
    if (analysis == null) {
      return Center(
        child: Text(
          'Add ingredients to get chef guidance.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final missing = analysis.missingElements;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Next best additions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _reshuffleGuided,
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (missing.isNotEmpty)
          Text(
            'We’ll only suggest ingredients that improve your dish (and we randomize within those).',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        const SizedBox(height: 14),
        if (_guided.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.35),
              ),
            ),
            child: Text(
              'Looks balanced. You can still browse for optional upgrades.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _guided.map((s) {
              final name = s.ingredient.name;
              final isSelected = widget.selectedIngredients.contains(name);
              return _IngredientSuggestionChip(
                name: name,
                reason: s.reason,
                isSelected: isSelected,
                onTap: isSelected ? null : () => _add(name),
              );
            }).toList(),
          ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: () {
            _tabController.animateTo(1);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _searchFocus.requestFocus();
            });
          },
          child: const Text('Browse all ingredients'),
        ),
      ],
    );
  }

  Widget _buildCarrierStart(
    BuildContext context,
    IngredientSelectionState ingredientState,
  ) {
    final theme = Theme.of(context);

    if (ingredientState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final carriers = _suggestCarriers(ingredientState);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Text(
          'Start with a carrier',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A carrier gives structure (protein, grain, or a hearty vegetable).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: carriers.map((i) {
            final name = i.name;
            return ActionChip(
              label: Text(name),
              avatar: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => _add(name),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: () {
            _tabController.animateTo(1);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _searchFocus.requestFocus();
            });
          },
          child: const Text('Browse instead'),
        ),
      ],
    );
  }

  List<Ingredient> _suggestCarriers(IngredientSelectionState s) {
    // Return ALL ingredients that can be carriers, not just a sample
    // Filter to only show ingredients that can actually be carriers
    return s.allIngredients
        .where((i) => i.canBeCarrier)
        .toList();
  }

  Widget _buildBrowse(
    BuildContext context,
    IngredientSelectionState ingredientState,
  ) {
    final theme = Theme.of(context);

    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty;

    final categories = <String>[
      'All',
      ...ingredientState.categorizedIngredients.keys.toList()..sort(),
    ];

    final items = isSearching
        ? ingredientState.searchResults
        : (_selectedCategory == 'All'
            ? ingredientState.allIngredients
            : (ingredientState.categorizedIngredients[_selectedCategory] ?? const []));

    // Show ALL items, no limit
    final visibleItems = items;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Search ingredients',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(ingredientProvider.notifier).clearSearch();
                      FocusScope.of(context).requestFocus(_searchFocus);
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear',
                  ),
          ),
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: 14),
        if (!isSearching) ...[
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final c = categories[idx];
                final selected = c == _selectedCategory;
                return FilterChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (_selectedCategory == 'All')
            Text(
              'Tip: use search for anything not shown here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (ingredientState.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: CircularProgressIndicator(),
          ))
        else if (visibleItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.35),
              ),
            ),
            child: Text(
              isSearching ? 'No results for "$query".' : 'No ingredients found.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleItems.map((i) {
              final name = i.name;
              final selected = widget.selectedIngredients.contains(name);
              return FilterChip(
                label: Text(name),
                selected: selected,
                onSelected: selected ? null : (_) => _add(name),
                avatar: selected
                    ? const Icon(Icons.check_circle_rounded, size: 18)
                    : const Icon(Icons.add_rounded, size: 18),
                selectedColor: AppColors.primary.withOpacity(0.14),
                showCheckmark: false,
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _IngredientSuggestionChip extends StatelessWidget {
  const _IngredientSuggestionChip({
    required this.name,
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String reason;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.surfaceVariant.withOpacity(0.25)
            : theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onSurface.withOpacity(0.55)
                  : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isSelected
                        ? theme.colorScheme.onSurface.withOpacity(0.55)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

