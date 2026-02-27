import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recipe_card_horizontal.dart';
import '../../../core/constants/colors.dart';
import '../../../services/supabase_service.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

String _greetingEmoji() {
  final hour = DateTime.now().hour;
  if (hour < 12) return '☀️';
  if (hour < 18) return '👋';
  return '🌙';
}

String? _userDisplayName() {
  final user = SupabaseService.getCurrentUser();
  if (user == null) return null;
  final name = user.userMetadata?['full_name'] as String?;
  if (name != null && name.isNotEmpty) return name;
  final email = user.email;
  if (email != null && email.isNotEmpty) {
    return email.split('@').first;
  }
  return null;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadRecents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);
    final horizontalPadding = 20.0;
    const sectionSpacing = 32.0;
    final isDark = theme.brightness == Brightness.dark;
    const displayNameFallback = 'Chef';
    final displayName = _userDisplayName() ?? displayNameFallback;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.03),
                    theme.scaffoldBackgroundColor,
                  ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero header with personalized greeting
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, $displayName ${_greetingEmoji()}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                        const SizedBox(height: 8),
                        Text(
                          'What would you like to cook today?',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w400,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),
                ),

                // Quick Actions - primary CTA
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      sectionSpacing,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick start',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: QuickActionCard(
                                title: 'Create Recipe',
                                subtitle: 'AI-crafted from ingredients',
                                icon: Icons.auto_awesome_rounded,
                                onTap: () => context.go('/generate'),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 150.ms)
                                .slideX(begin: -0.1, end: 0)
                                .scale(begin: const Offset(0.98, 0.98)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QuickActionCard(
                                title: 'My Recipes',
                                subtitle: 'Saved & favorites',
                                icon: Icons.bookmark_rounded,
                                onTap: () => context.go('/saved'),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideX(begin: 0.1, end: 0)
                                .scale(begin: const Offset(0.98, 0.98)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        QuickActionCard(
                          title: 'Scan ingredients',
                          subtitle: 'Use your camera to add ingredients',
                          icon: Icons.camera_alt_rounded,
                          onTap: () => context.push('/scan'),
                        )
                            .animate()
                            .fadeIn(delay: 250.ms)
                            .slideY(begin: 0.08, end: 0)
                            .scale(begin: const Offset(0.98, 0.98)),
                      ],
                    ),
                  ),
                ),

                // Your recipes section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      sectionSpacing,
                      horizontalPadding,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.recents.isEmpty && !state.isLoading
                              ? 'Get started'
                              : 'Your recipes',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (state.recents.isNotEmpty)
                          TextButton(
                            onPressed: () => context.go('/saved'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'See all',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 14, bottom: 24 + padding.bottom),
                    child: _buildRecents(context, state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecents(BuildContext context, HomeState state) {
    const cardHeight = RecipeCardHorizontal.imageHeight +
        RecipeCardHorizontal.contentHeight;
    const cardSpacing = 12.0;

    if (state.isLoading) {
      return SizedBox(
        height: cardHeight + 8,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: cardSpacing),
          itemBuilder: (_, i) => Container(
            width: RecipeCardHorizontal.cardWidth,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppBorderRadius.large),
            ),
          )
              .animate()
              .shimmer(duration: 1200.ms),
        ),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Couldn\'t load recipes. Pull to retry.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.recents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: InkWell(
            onTap: () => context.go('/generate'),
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No recipes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first Chef recipe with AI.\nPick ingredients and we\'ll craft something delicious.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go('/generate'),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Create recipe'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn()
            .scale(begin: const Offset(0.96, 0.96)),
      );
    }

    return SizedBox(
      height: cardHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.recents.length,
        cacheExtent: 400,
        separatorBuilder: (_, __) => const SizedBox(width: cardSpacing),
        itemBuilder: (context, index) {
          final recipe = state.recents[index];
          return RecipeCardHorizontal(
            recipe: recipe,
            onTap: () => context.go('/recipe/${recipe.id}', extra: recipe),
          )
              .animate()
              .fadeIn(delay: (50 * index).ms)
              .slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }
}
