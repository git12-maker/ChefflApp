import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';

/// Step 1: Start - Choose main ingredient category
/// Matches app_voorstel_v2.md Scherm 1
class WizardStartStep extends ConsumerWidget {
  const WizardStartStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Title
          Text(
            '🍳 NIEUW GERECHT MAKEN',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Category selection cards
          Text(
            'Kies je hoofdingrediënt',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Category grid
          _CategoryGrid(
            onCategorySelected: (category) {
              notifier.selectCategory(category);
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final Function(String) onCategorySelected;

  const _CategoryGrid({required this.onCategorySelected});

  final List<Map<String, dynamic>> _categories = const [
    {
      'name': 'Vis',
      'emoji': '🐟',
      'category': 'Fish',
    },
    {
      'name': 'Gevogelte',
      'emoji': '🍗',
      'category': 'Poultry',
    },
    {
      'name': 'Vlees',
      'emoji': '🥩',
      'category': 'Meat',
    },
    {
      'name': 'Groente',
      'emoji': '🥕',
      'category': 'Vegetables',
    },
    {
      'name': 'Peulvruchten',
      'emoji': '🫘',
      'category': 'Legumes',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryCard(
          emoji: category['emoji'] as String,
          name: category['name'] as String,
          onTap: () => onCategorySelected(category['category'] as String),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.emoji,
    required this.name,
    required this.onTap,
  });

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
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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
