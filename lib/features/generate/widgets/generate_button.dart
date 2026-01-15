import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class GenerateButton extends StatelessWidget {
  const GenerateButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loadingLabel ?? 'Cooking up something tasty...'),
                ],
              )
            : const Text('Generate Recipe'),
      ),
    );
  }
}
