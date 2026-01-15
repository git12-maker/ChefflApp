import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recipe_card_horizontal.dart';
import '../widgets/cuisine_chip.dart';
import '../widgets/section_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen is first built (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadRecents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              title: const GreetingHeader(),
            ),
            // Section headers with padding
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Quick actions header
                    const SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Quick actions grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        title: 'Generate Recipe',
                        subtitle: 'AI-crafted ideas',
                        icon: Icons.auto_awesome,
                        onTap: () => context.go('/generate'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: QuickActionCard(
                        title: 'Scan Ingredients',
                        subtitle: 'AI-powered recognition',
                        icon: Icons.qr_code_scanner,
                        onTap: () => context.go('/scan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Section headers with padding
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Recent Recipes header
                    SectionHeader(
                      title: 'Recent Recipes',
                      onSeeAll: () => context.go('/saved'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Full-width carousel for recent recipes
            SliverToBoxAdapter(
              child: _buildRecents(context, state),
            ),
            // Continue with rest of content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Try something new
                    const SectionHeader(title: 'Try Something New'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final c in ['Italian', 'Asian', 'Mexican', 'Healthy'])
                          CuisineChip(
                            label: c,
                            onTap: () => context.go('/generate'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecents(BuildContext context, HomeState state) {
    if (state.isLoading) {
      return SizedBox(
        height: 240,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20), // Full-width padding
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => Container(
            width: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    if (state.error != null) {
      return Text(
        'Error loading recipes',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red,
            ),
      );
    }

    if (state.recents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No recipes yet. Try generating one!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20), // Full-width padding
        itemCount: state.recents.length,
        cacheExtent: 500, // Cache more items for smoother scrolling
        itemBuilder: (context, index) {
          final recipe = state.recents[index];
          return RepaintBoundary(
            child: RecipeCardHorizontal(
              recipe: recipe,
              onTap: () => context.go('/recipe/${recipe.id}', extra: recipe),
            ),
          );
        },
      ),
    );
  }
}
