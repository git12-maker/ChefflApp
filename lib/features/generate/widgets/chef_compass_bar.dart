import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/culinary_intelligence_service.dart';

class ChefCompassBar extends StatelessWidget {
  const ChefCompassBar({
    super.key,
    required this.score,
    required this.missingElements,
    required this.onTap,
  });

  final int score;
  final List<MissingElement> missingElements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red.shade400;
    }

    // Show all missing elements, not just a limited subset
    final missingLabels = missingElements.map(_labelForMissing).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.xlargeAll,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: AppBorderRadius.xlargeAll,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: scoreColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Chef Compass',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: scoreColor.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            '$score/100',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (missingElements.isEmpty)
                      Text(
                        'Looks balanced. Tap to see details.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Missing:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          ...missingLabels.map((label) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              )),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _labelForMissing(MissingElement e) {
    switch (e.type) {
      case ElementType.carrier:
        return 'carrier';
      case ElementType.umami:
        return 'umami';
      case ElementType.acid:
        return 'acid';
      case ElementType.texture:
        return 'texture';
      case ElementType.crunch:
        return 'crunch';
      case ElementType.freshness:
        return 'freshness';
      case ElementType.richness:
        return 'richness';
      case ElementType.aroma:
        return 'aroma';
      case ElementType.mouthfeel:
        return 'mouthfeel';
      case ElementType.cookingMethod:
        return 'cooking method';
    }
  }
}

