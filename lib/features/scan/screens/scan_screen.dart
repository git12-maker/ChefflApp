import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../providers/scan_provider.dart';
import '../../generate/providers/generate_provider.dart';
import '../widgets/camera_placeholder.dart';
import '../widgets/image_preview.dart';
import '../widgets/ingredient_result_chip.dart';
import '../widgets/add_ingredient_input.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  void initState() {
    super.initState();
    // Request camera permission when screen opens
    // This ensures iOS registers it and shows it in Settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanProvider.notifier).initializePermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(scanProvider);
    final notifier = ref.read(scanProvider.notifier);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scan Ingredients',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subheader
              Text(
                'Take a photo of your fridge or ingredients',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Image selection area
              if (state.selectedImage == null) ...[
                const CameraPlaceholder(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: notifier.takePhoto,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text(
                          'Take Photo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: notifier.pickFromGallery,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Ensure good lighting and clear visibility of ingredients for best results.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ImagePreview(
                  imageFile: state.selectedImage!,
                  onRetake: notifier.retakePhoto,
                ),
                const SizedBox(height: 20),
                if (!state.isAnalyzing && state.recognizedIngredients.isEmpty)
                  ElevatedButton.icon(
                    onPressed: notifier.analyzeImage,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text(
                      'Analyze Ingredients',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
              ],

              // Loading state
              if (state.isAnalyzing) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.analyzingMessage ?? 'Analyzing...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error state
              if (state.error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Results
              if (state.recognizedIngredients.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recognized Ingredients',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${state.selectedIngredients.length} selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: state.recognizedIngredients.map((ingredient) {
                    final isSelected = state.selectedIngredients.contains(ingredient.name);
                    return IngredientResultChip(
                      ingredient: ingredient,
                      isSelected: isSelected,
                      onTap: () => notifier.toggleIngredient(ingredient.name),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add Missing Ingredients',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                AddIngredientInput(
                  onAdd: notifier.addManualIngredient,
                ),
                if (state.manualIngredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: state.manualIngredients.map((ingredient) {
                      return Chip(
                        label: Text(ingredient),
                        onDeleted: () => notifier.removeManualIngredient(ingredient),
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                        deleteIconColor: AppColors.accent,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: state.allSelectedIngredients.isEmpty
                      ? null
                      : () async {
                          // Set ingredients in generate provider first
                          ref.read(generateProvider.notifier).setInitialIngredients(
                                state.allSelectedIngredients,
                              );
                          // Navigate to generate tab
                          if (context.mounted) {
                            context.go('/generate');
                          }
                        },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'Use ${state.allSelectedIngredients.length} Ingredients',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}
