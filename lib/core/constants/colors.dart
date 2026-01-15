import 'package:flutter/material.dart';

/// Cheffl color palette
/// Primary: Forest Green (#1B4D3E)
/// Accent: Warm Gold (#D4A574)
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1B4D3E);
  static const Color primaryDark = Color(0xFF153A2E);
  static const Color primaryLight = Color(0xFF2A6B5A);

  // Accent Colors
  static const Color accent = Color(0xFFD4A574);
  static const Color accentDark = Color(0xFFB8905F);
  static const Color accentLight = Color(0xFFE8C19A);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightOnBackground = Color(0xFF212121);
  static const Color lightOnSurface = Color(0xFF424242);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkDivider = Color(0xFF424242);
}

/// Consistent border radius values for the app
class AppBorderRadius {
  AppBorderRadius._();
  
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 20.0;
  
  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius xlargeAll = BorderRadius.all(Radius.circular(xlarge));
}
