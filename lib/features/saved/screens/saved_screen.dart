import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../providers/saved_provider.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/recipe_card_grid.dart';
import '../widgets/recipe_search_bar.dart';
import '../widgets/empty_saved_state.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen is first built (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedProvider);
    final notifier = ref.read(savedProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Recipes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeSearchBar(onChanged: notifier.setSearch),
                    const SizedBox(height: 20),
                    FilterTabs(
                      isFavoritesOnly: state.filterFavorites,
                      onToggle: notifier.setFavoritesOnly,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: _buildContent(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SavedState state,
    SavedNotifier notifier,
  ) {
    if (state.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (state.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading recipes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    if (state.filtered.isEmpty) {
      return SliverFillRemaining(
        child: EmptySavedState(
          onGenerate: () => context.go('/generate'),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Image: 150px + Flexible content. 0.65 gives adequate height to prevent overflow.
        childAspectRatio: 0.65,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final recipe = state.filtered[index];
          return RepaintBoundary(
            child: Dismissible(
            key: ValueKey(recipe.id ?? index),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: AppBorderRadius.xlargeAll,
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Delete recipe',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this recipe?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) => notifier.delete(recipe.id ?? ''),
            child: RecipeCardGrid(
              recipe: recipe,
              onTap: () => context.go('/recipe/${recipe.id}', extra: recipe),
              onFavoriteToggle: () => notifier.toggleFavorite(
                recipe.id ?? '',
                !recipe.isFavorite,
              ),
            ),
            ),
          );
        },
        childCount: state.filtered.length,
      ),
    );
  }
}
