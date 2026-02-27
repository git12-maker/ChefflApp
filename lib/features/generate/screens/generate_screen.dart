import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ingredient_provider.dart';
import '../providers/smaakprofiel_wizard_provider.dart';
import 'smaakprofiel_wizard_screen.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  @override
  void initState() {
    super.initState();
    // Reset wizard state when navigating to generate screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset wizard for fresh start
      ref.read(smaakprofielWizardProvider.notifier).reset();
      // Refresh ingredients to get latest images from database
      ref.read(ingredientProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SmaakprofielWizardScreen();
  }
}
