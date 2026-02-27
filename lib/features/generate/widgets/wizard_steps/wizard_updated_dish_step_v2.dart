import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/smaakprofiel.dart';
import '../../../../shared/models/balans_analyse.dart';
import '../../providers/smaakprofiel_wizard_provider.dart';
import '../../widgets/smaakprofiel_visualisatie.dart';

/// Step 7: Updated dish view - COMPACT REDESIGN
/// World-class UI/UX with minimal scrolling, maximum information density
class WizardUpdatedDishStepV2 extends ConsumerWidget {
  const WizardUpdatedDishStepV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(smaakprofielWizardProvider);
    final notifier = ref.read(smaakprofielWizardProvider.notifier);

    if (state.currentProfile == null || state.balanceAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final lastAdded = state.additionalIngredients.isNotEmpty
        ? state.additionalIngredients.last
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header with profile summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jouw Gerecht',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Compact ingredient chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (state.mainIngredient != null)
                          _IngredientChip(
                            name: state.mainIngredient!.name,
                            isMain: true,
                          ),
                        ...state.additionalIngredients.map((ing) =>
                            _IngredientChip(name: ing.name)),
                      ],
                    ),
                  ],
                ),
              ),
              // Compact profile indicator
              SmaakprofielVisualisatie(
                smaakprofiel: state.currentProfile!,
                balans: state.balanceAnalysis,
                compact: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dynamic feedback card - SPECIFIC and ACTION-BASED
          if (lastAdded != null)
            _DynamicFeedbackCard(
              lastAdded: lastAdded,
              previousProfile: state.previousProfile,
              currentProfile: state.currentProfile!,
              balanceAnalysis: state.balanceAnalysis!,
            ),

          const SizedBox(height: 12),

          // Compact profile visualization
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SmaakprofielVisualisatie(
              smaakprofiel: state.currentProfile!,
              balans: state.balanceAnalysis,
            ),
          ),

          const SizedBox(height: 12),

          // Compact missing elements with shuffle
          if (state.balanceAnalysis!.ontbrekendeElementen.isNotEmpty)
            _MissingElementsSection(
              missingElements: state.balanceAnalysis!.ontbrekendeElementen,
              onShuffle: () => notifier.shuffleSuggestions(),
            ),

          const Spacer(),

          // Compact action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.goToAddIngredients(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Toevoegen'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => notifier.finishDish(),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Afronden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}

class _IngredientChip extends StatelessWidget {
  final String name;
  final bool isMain;

  const _IngredientChip({required this.name, this.isMain = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMain
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.grey200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
          color: isMain ? AppColors.primary : null,
        ),
      ),
    );
  }
}

class _DynamicFeedbackCard extends StatelessWidget {
  final dynamic lastAdded;
  final Smaakprofiel? previousProfile;
  final Smaakprofiel currentProfile;
  final BalansAnalyse balanceAnalysis;

  const _DynamicFeedbackCard({
    required this.lastAdded,
    this.previousProfile,
    required this.currentProfile,
    required this.balanceAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedback = _generateSpecificFeedback();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _FeedbackData _generateSpecificFeedback() {
    final strak = currentProfile.mondgevoel.strak;
    final filmend = currentProfile.mondgevoel.filmend;
    final type = currentProfile.smaakrijkdom.type;
    final gehalte = currentProfile.smaakrijkdom.gehalte;

    // Calculate what changed
    final strakChange = previousProfile != null
        ? strak - previousProfile!.mondgevoel.strak
        : 0.0;
    final filmendChange = previousProfile != null
        ? filmend - previousProfile!.mondgevoel.filmend
        : 0.0;
    final typeChange = previousProfile != null
        ? type - previousProfile!.smaakrijkdom.type
        : 0.0;

    // Specific feedback based on what was added
    if (strakChange > 0.1) {
      return _FeedbackData(
        title: 'Frisheid toegevoegd!',
        message: '${lastAdded.name} heeft het gerecht frisser gemaakt. '
            'De balans tussen strak en filmend is nu ${_getBalanceDescription(strak, filmend)}.',
      );
    } else if (filmendChange > 0.1) {
      return _FeedbackData(
        title: 'Romigheid verhoogd!',
        message: '${lastAdded.name} heeft het gerecht romiger gemaakt. '
            'Perfect voor een ${type > 0.6 ? "rijp" : "fris"} gerecht.',
      );
    } else if (typeChange > 0.1) {
      return _FeedbackData(
        title: 'Diepte toegevoegd!',
        message: '${lastAdded.name} heeft rijpe tonen toegevoegd. '
            'Het gerecht heeft nu meer complexiteit.',
      );
    } else if (typeChange < -0.1) {
      return _FeedbackData(
        title: 'Verfrissing toegevoegd!',
        message: '${lastAdded.name} heeft frisse tonen toegevoegd. '
            'Het gerecht is nu lichter en verfrissender.',
      );
    } else if (gehalte > 0.6) {
      return _FeedbackData(
        title: 'Smaakintensiteit verhoogd!',
        message: '${lastAdded.name} heeft het gerecht smaakrijker gemaakt. '
            'Perfect voor een krachtig gerecht.',
      );
    } else if (balanceAnalysis.isBalanced) {
      return _FeedbackData(
        title: 'Perfecte balans!',
        message: 'Het gerecht heeft nu een goede balans tussen alle elementen. '
            'Je kunt nog ingrediënten toevoegen voor textuur of complexiteit.',
      );
    } else {
      return _FeedbackData(
        title: 'Goede toevoeging!',
        message: '${lastAdded.name} past goed bij je gerecht. '
            'Overweeg nog ${_getNextSuggestion()} voor optimale balans.',
      );
    }
  }

  String _getBalanceDescription(double strak, double filmend) {
    final ratio = filmend > 0 ? strak / filmend : 0;
    if (ratio > 0.7 && ratio < 1.3) return 'uitstekend gebalanceerd';
    if (ratio > 1.3) return 'iets te fris';
    return 'iets te romig';
  }

  String _getNextSuggestion() {
    if (balanceAnalysis.ontbrekendeElementen.isEmpty) return 'textuurvariatie';
    final first = balanceAnalysis.ontbrekendeElementen.first;
    switch (first.type) {
      case OntbrekendElementType.strak:
        return 'iets zuurs';
      case OntbrekendElementType.filmend:
        return 'iets romigs';
      case OntbrekendElementType.fris:
        return 'iets fris';
      case OntbrekendElementType.rijp:
        return 'iets rijps';
      default:
        return 'textuurvariatie';
    }
  }
}

class _FeedbackData {
  final String title;
  final String message;

  _FeedbackData({required this.title, required this.message});
}

class _MissingElementsSection extends ConsumerStatefulWidget {
  final List<OntbrekendElement> missingElements;
  final VoidCallback onShuffle;

  const _MissingElementsSection({
    required this.missingElements,
    required this.onShuffle,
  });

  @override
  ConsumerState<_MissingElementsSection> createState() =>
      _MissingElementsSectionState();
}

class _MissingElementsSectionState
    extends ConsumerState<_MissingElementsSection> {
  List<OntbrekendElement> _shuffledElements = [];

  @override
  void initState() {
    super.initState();
    _shuffledElements = List.from(widget.missingElements);
  }

  void _shuffle() {
    setState(() {
      _shuffledElements = List.from(widget.missingElements)..shuffle();
    });
    widget.onShuffle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Suggesties',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.shuffle, size: 18),
              onPressed: _shuffle,
              tooltip: 'Nieuwe suggesties',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _shuffledElements.take(4).map((element) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getPriorityColor(element.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPriorityColor(element.priority).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPriorityIcon(element.priority),
                    size: 14,
                    color: _getPriorityColor(element.priority),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      element.suggestie ?? element.reason,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getPriorityColor(element.priority),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getPriorityColor(MissingPriority priority) {
    switch (priority) {
      case MissingPriority.high:
        return Colors.red;
      case MissingPriority.medium:
        return Colors.orange;
      case MissingPriority.low:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon(MissingPriority priority) {
    switch (priority) {
      case MissingPriority.high:
        return Icons.priority_high;
      case MissingPriority.medium:
        return Icons.info_outline;
      case MissingPriority.low:
        return Icons.lightbulb_outline;
    }
  }
}
