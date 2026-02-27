import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';

/// Compact analysis summary that's always visible
/// Can be expanded to show full details
class WizardAnalysisSummary extends StatefulWidget {
  const WizardAnalysisSummary({
    super.key,
    required this.analysis,
    required this.onAddIngredient,
  });

  final CompositionAnalysis analysis;
  final ValueChanged<String> onAddIngredient;

  @override
  State<WizardAnalysisSummary> createState() => _WizardAnalysisSummaryState();
}

class _WizardAnalysisSummaryState extends State<WizardAnalysisSummary> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = widget.analysis.overallScore;
    final missing = widget.analysis.missingElements;

    // Score color based on value
    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.success;
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact view (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Score circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withOpacity(0.1),
                      border: Border.all(
                        color: scoreColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Summary text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getScoreMessage(score),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        if (missing.isNotEmpty)
                          Text(
                            _getMissingSummary(missing),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            'Well balanced composition!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

          // Expanded view
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flavor balance
                  _buildSection(
                    context,
                    'Flavor Balance',
                    _buildFlavorBalance(context),
                  ),
                  const SizedBox(height: 16),
                  // Missing elements
                  if (missing.isNotEmpty) ...[
                    _buildSection(
                      context,
                      'What\'s Missing',
                      _buildMissingElements(context, missing),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Suggestions
                  if (widget.analysis.suggestions.isNotEmpty) ...[
                    _buildSection(
                      context,
                      'Smart Suggestions',
                      _buildSuggestions(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
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

  Widget _buildFlavorBalance(BuildContext context) {
    final profile = widget.analysis.flavorProfile;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFlavorChip(context, 'Sweet', profile.sweetness),
        _buildFlavorChip(context, 'Salty', profile.saltiness),
        _buildFlavorChip(context, 'Sour', profile.sourness),
        _buildFlavorChip(context, 'Bitter', profile.bitterness),
        _buildFlavorChip(context, 'Umami', profile.umami),
      ],
    );
  }

  Widget _buildFlavorChip(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    final intensity = (value * 100).round();
    final color = intensity > 50 ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$intensity%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMissingElements(BuildContext context, List<MissingElement> missing) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: missing.map((element) {
        final priorityColor = element.priority == MissingPriority.high
            ? AppColors.error
            : element.priority == MissingPriority.medium
                ? AppColors.warning
                : AppColors.info;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: priorityColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: priorityColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  element.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: priorityColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    // Show all suggestions, not just a limited subset
    final suggestions = widget.analysis.suggestions;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(
            suggestion.ingredient.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          onPressed: () => widget.onAddIngredient(suggestion.ingredient.name),
          avatar: Icon(
            Icons.add_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 80) return 'Excellent composition!';
    if (score >= 60) return 'Good start, keep building';
    if (score >= 40) return 'Getting there';
    return 'Let\'s add more ingredients';
  }

  String _getMissingSummary(List<MissingElement> missing) {
    final high = missing.where((e) => e.priority == MissingPriority.high).length;
    final med = missing.where((e) => e.priority == MissingPriority.medium).length;
    
    if (high > 0) return '$high important element${high == 1 ? '' : 's'} missing';
    if (med > 0) return '$med element${med == 1 ? '' : 's'} to improve';
    return 'Minor improvements possible';
  }
}
