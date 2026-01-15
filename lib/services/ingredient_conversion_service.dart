import '../shared/models/recipe.dart';
import '../shared/models/user_preferences.dart';

/// Service for converting ingredient amounts based on servings and measurement units
class IngredientConversionService {
  IngredientConversionService._();
  static final IngredientConversionService instance = IngredientConversionService._();

  /// Convert ingredient amount based on servings multiplier
  /// Original servings -> new servings
  String convertAmountForServings(
    String amount,
    int originalServings,
    int newServings,
  ) {
    if (originalServings == newServings || originalServings == 0) {
      return amount;
    }

    final multiplier = newServings / originalServings;
    return _scaleAmount(amount, multiplier);
  }

  /// Convert ingredient amount between metric and imperial
  String convertAmountForUnit(
    String amount,
    MeasurementUnit fromUnit,
    MeasurementUnit toUnit,
  ) {
    if (fromUnit == toUnit) {
      return amount;
    }

    return _convertUnit(amount, fromUnit, toUnit);
  }

  /// Scale an amount by a multiplier
  String _scaleAmount(String amount, double multiplier) {
    // Try to extract number and unit
    final amountLower = amount.toLowerCase().trim();
    
    // Handle fractions (e.g., "1/2 cup", "1 1/2 cups")
    final fractionMatch = RegExp(r'(\d+)\s*(\d+)/(\d+)').firstMatch(amountLower);
    if (fractionMatch != null) {
      final whole = int.parse(fractionMatch.group(1)!);
      final num = int.parse(fractionMatch.group(2)!);
      final den = int.parse(fractionMatch.group(3)!);
      final total = whole + (num / den);
      final scaled = total * multiplier;
      return _formatAmount(scaled, amount);
    }

    // Handle simple fractions (e.g., "1/2", "3/4")
    final simpleFractionMatch = RegExp(r'(\d+)/(\d+)').firstMatch(amountLower);
    if (simpleFractionMatch != null) {
      final num = int.parse(simpleFractionMatch.group(1)!);
      final den = int.parse(simpleFractionMatch.group(2)!);
      final total = num / den;
      final scaled = total * multiplier;
      return _formatAmount(scaled, amount);
    }

    // Handle decimal numbers (e.g., "1.5", "2.25")
    final decimalMatch = RegExp(r'(\d+\.?\d*)').firstMatch(amountLower);
    if (decimalMatch != null) {
      final value = double.tryParse(decimalMatch.group(1)!);
      if (value != null) {
        final scaled = value * multiplier;
        return _formatAmount(scaled, amount);
      }
    }

    // Handle whole numbers
    final wholeMatch = RegExp(r'^(\d+)').firstMatch(amountLower);
    if (wholeMatch != null) {
      final value = int.tryParse(wholeMatch.group(1)!);
      if (value != null) {
        final scaled = value * multiplier;
        return _formatAmount(scaled, amount);
      }
    }

    // If we can't parse, return original with multiplier note
    if (multiplier != 1.0) {
      return '$amount (×${multiplier.toStringAsFixed(2)})';
    }
    return amount;
  }

  /// Format a scaled amount nicely
  String _formatAmount(double value, String originalAmount) {
    // Extract unit from original amount
    final unitMatch = RegExp(r'[a-z]+').firstMatch(originalAmount.toLowerCase());
    final unit = unitMatch?.group(0) ?? '';

    // Format the number
    if (value == value.roundToDouble()) {
      // Whole number
      return '${value.toInt()}${unit.isNotEmpty ? ' $unit' : ''}';
    } else if (value < 1) {
      // Fraction
      final fraction = _decimalToFraction(value);
      return '$fraction${unit.isNotEmpty ? ' $unit' : ''}';
    } else {
      // Decimal with 1-2 decimal places
      final rounded = double.parse(value.toStringAsFixed(2));
      if (rounded == rounded.roundToDouble()) {
        return '${rounded.toInt()}${unit.isNotEmpty ? ' $unit' : ''}';
      }
      return '${rounded.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')}${unit.isNotEmpty ? ' $unit' : ''}';
    }
  }

  /// Convert decimal to fraction (e.g., 0.5 -> "1/2")
  String _decimalToFraction(double value) {
    if (value >= 1) return value.toString();
    
    // Common fractions
    final commonFractions = [
      (0.125, '1/8'),
      (0.25, '1/4'),
      (0.333, '1/3'),
      (0.5, '1/2'),
      (0.667, '2/3'),
      (0.75, '3/4'),
    ];

    for (final (decimal, fraction) in commonFractions) {
      if ((value - decimal).abs() < 0.01) {
        return fraction;
      }
    }

    // Approximate
    final den = 16;
    final num = (value * den).round();
    if (num == 0) return '0';
    if (num == den) return '1';
    
    // Simplify fraction
    final gcd = _gcd(num, den);
    final simplifiedNum = num ~/ gcd;
    final simplifiedDen = den ~/ gcd;
    
    return '$simplifiedNum/$simplifiedDen';
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  /// Convert between metric and imperial units
  String _convertUnit(String amount, MeasurementUnit fromUnit, MeasurementUnit toUnit) {
    if (fromUnit == toUnit) return amount;
    
    final amountLower = amount.toLowerCase().trim();
    
    // Handle "as needed", "to taste", etc.
    if (amountLower.contains('as needed') || 
        amountLower.contains('to taste') ||
        amountLower.contains('to serve') ||
        amountLower.isEmpty) {
      return amount; // Don't convert these
    }
    
    // Extract number (handle fractions, decimals, whole numbers)
    double? number;
    String? unit;
    
    // Try to extract fraction first (e.g., "1/2 cup", "1 1/2 cups")
    final fractionMatch = RegExp(r'(\d+)\s*(\d+)/(\d+)').firstMatch(amountLower);
    if (fractionMatch != null) {
      final whole = int.parse(fractionMatch.group(1)!);
      final num = int.parse(fractionMatch.group(2)!);
      final den = int.parse(fractionMatch.group(3)!);
      number = whole + (num / den);
      // Extract unit after fraction
      final unitStart = fractionMatch.end;
      if (unitStart < amountLower.length) {
        unit = amountLower.substring(unitStart).trim();
      }
    } else {
      // Try simple fraction (e.g., "1/2 cup")
      final simpleFractionMatch = RegExp(r'(\d+)/(\d+)').firstMatch(amountLower);
      if (simpleFractionMatch != null) {
        final num = int.parse(simpleFractionMatch.group(1)!);
        final den = int.parse(simpleFractionMatch.group(2)!);
        number = num / den;
        // Extract unit after fraction
        final unitStart = simpleFractionMatch.end;
        if (unitStart < amountLower.length) {
          unit = amountLower.substring(unitStart).trim();
        }
      } else {
        // Extract decimal or whole number with unit
        // Better pattern: number followed by optional space and unit text
        // Try pattern with explicit unit first: "200 g", "1 cup", etc.
        final numberWithUnitMatch = RegExp(r'(\d+\.?\d*)\s+([a-z]+(?:\s+[a-z]+)?)', caseSensitive: false).firstMatch(amountLower);
        if (numberWithUnitMatch != null) {
          number = double.tryParse(numberWithUnitMatch.group(1)!);
          unit = numberWithUnitMatch.group(2)?.trim();
        } else {
          // Fallback: just extract number, then find unit separately
          final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(amountLower);
          if (numberMatch != null) {
            number = double.tryParse(numberMatch.group(1)!);
            // Extract everything after the number as potential unit
            final unitStart = numberMatch.end;
            if (unitStart < amountLower.length) {
              unit = amountLower.substring(unitStart).trim();
            }
          }
        }
      }
    }
    
    if (number == null) return amount;
    
    // Clean up unit (remove extra spaces, punctuation, but keep spaces for "fl oz")
    if (unit != null && unit.isNotEmpty) {
      unit = unit.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
      // Normalize multiple spaces to single space
      unit = unit.replaceAll(RegExp(r'\s+'), ' ');
    }
    
    // If no unit found, try to detect from common patterns in the original amount
    if (unit == null || unit.isEmpty) {
      // Check if amount contains unit keywords (check longer units first)
      final unitKeywords = [
        'fluid ounce', 'fluid ounces', 'fl oz',
        'kilogram', 'kilograms', 'kg',
        'milliliter', 'milliliters', 'ml',
        'tablespoon', 'tablespoons', 'tbsp',
        'teaspoon', 'teaspoons', 'tsp',
        'gram', 'grams', 'g',
        'liter', 'liters', 'l',
        'ounce', 'ounces', 'oz',
        'pound', 'pounds', 'lb',
        'cup', 'cups',
        'inch', 'inches', 'in',
        'foot', 'feet', 'ft',
      ];
      
      for (final keyword in unitKeywords) {
        // Use word boundaries to avoid partial matches
        final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        if (pattern.hasMatch(amountLower)) {
          unit = keyword;
          break;
        }
      }
    }

    // Final unit detection - try one more time if still empty
    String finalUnit = unit ?? '';
    if (finalUnit.isEmpty) {
      // Check the original amount string for unit keywords
      final unitKeywords = [
        'fluid ounce', 'fluid ounces', 'fl oz',
        'kilogram', 'kilograms', 'kg',
        'milliliter', 'milliliters', 'ml',
        'tablespoon', 'tablespoons', 'tbsp',
        'teaspoon', 'teaspoons', 'tsp',
        'gram', 'grams', 'g',
        'liter', 'liters', 'l',
        'ounce', 'ounces', 'oz',
        'pound', 'pounds', 'lb',
        'cup', 'cups',
      ];
      
      for (final keyword in unitKeywords) {
        final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
        if (pattern.hasMatch(amountLower)) {
          finalUnit = keyword;
          break;
        }
      }
    }

    // Conversion - only convert if unit was detected
    if (finalUnit.isNotEmpty) {
      if (fromUnit == MeasurementUnit.metric && toUnit == MeasurementUnit.imperial) {
        return _metricToImperial(number, finalUnit);
      } else if (fromUnit == MeasurementUnit.imperial && toUnit == MeasurementUnit.metric) {
        return _imperialToMetric(number, finalUnit);
      }
    }

    // If no unit detected, return original amount
    return amount;
  }

  String _metricToImperial(double value, String unit) {
    final unitLower = unit.toLowerCase().trim();
    
    // Weight conversions
    if (unitLower == 'g' || unitLower == 'gram' || unitLower == 'grams') {
      if (value < 28.35) {
        // Small amounts: show in oz with decimals
        return '${(value * 0.035274).toStringAsFixed(2)} oz';
      } else {
        // Larger amounts: show in oz or lb
        final oz = value * 0.035274;
        if (oz >= 16) {
          final lb = oz / 16;
          final remainingOz = oz % 16;
          if (remainingOz < 0.1) {
            return '${lb.toStringAsFixed(1)} lb';
          }
          return '${lb.toStringAsFixed(1)} lb ${remainingOz.toStringAsFixed(1)} oz';
        }
        return '${oz.toStringAsFixed(1)} oz';
      }
    }
    
    if (unitLower == 'kg' || unitLower == 'kilogram' || unitLower == 'kilograms') {
      final lb = value * 2.20462;
      if (lb >= 1) {
        return '${lb.toStringAsFixed(1)} lb';
      } else {
        // Convert to oz if less than 1 lb
        final oz = lb * 16;
        return '${oz.toStringAsFixed(1)} oz';
      }
    }
    
    // Volume conversions
    if (unitLower == 'ml' || unitLower == 'milliliter' || unitLower == 'milliliters') {
      if (value < 30) {
        // Small amounts: convert to tsp/tbsp
        final tsp = value / 4.92892;
        if (tsp < 3) {
          return '${tsp.toStringAsFixed(1)} tsp';
        } else {
          final tbsp = tsp / 3;
          return '${tbsp.toStringAsFixed(1)} tbsp';
        }
      } else {
        // Larger amounts: convert to fl oz or cups
        final flOz = value * 0.033814;
        if (flOz >= 8) {
          final cups = flOz / 8;
          return '${cups.toStringAsFixed(2)} cups';
        }
        return '${flOz.toStringAsFixed(1)} fl oz';
      }
    }
    
    if (unitLower == 'l' || unitLower == 'liter' || unitLower == 'liters') {
      final cups = value * 4.22675;
      if (cups >= 1) {
        return '${cups.toStringAsFixed(2)} cups';
      } else {
        // Convert to fl oz if less than 1 cup
        final flOz = cups * 8;
        return '${flOz.toStringAsFixed(1)} fl oz';
      }
    }
    
    // Length conversions (less common in recipes)
    if (unitLower == 'cm') {
      return '${(value * 0.393701).toStringAsFixed(1)} in';
    }
    if (unitLower == 'm') {
      return '${(value * 3.28084).toStringAsFixed(1)} ft';
    }
    
    // If unit not recognized, return original
    return '$value $unit';
  }

  String _imperialToMetric(double value, String unit) {
    final unitLower = unit.toLowerCase().trim();
    
    // If unit is empty, try to detect from common patterns
    if (unitLower.isEmpty) {
      // Default: assume oz for small numbers
      if (value < 16) {
        // Likely ounces
        final grams = value * 28.3495;
        if (grams >= 1000) {
          final kg = grams / 1000;
          return '${kg.toStringAsFixed(2)} kg';
        }
        return '${grams.toStringAsFixed(0)} g';
      }
      return '$value $unit'; // Return original if can't determine
    }
    
    // Weight conversions
    if (unitLower == 'oz' || unitLower == 'ounce' || unitLower == 'ounces') {
      final grams = value * 28.3495;
      if (grams >= 1000) {
        final kg = grams / 1000;
        return '${kg.toStringAsFixed(2)} kg';
      }
      return '${grams.toStringAsFixed(0)} g';
    }
    
    if (unitLower == 'lb' || unitLower == 'pound' || unitLower == 'pounds') {
      final kg = value * 0.453592;
      if (kg >= 1) {
        return '${kg.toStringAsFixed(2)} kg';
      } else {
        // Convert to grams if less than 1 kg
        final grams = kg * 1000;
        return '${grams.toStringAsFixed(0)} g';
      }
    }
    
    // Volume conversions
    if (unitLower == 'fl oz' || unitLower == 'fluid ounce' || unitLower == 'fluid ounces') {
      final ml = value * 29.5735;
      if (ml >= 1000) {
        final liters = ml / 1000;
        return '${liters.toStringAsFixed(2)} L';
      }
      return '${ml.toStringAsFixed(0)} ml';
    }
    
    if (unitLower == 'cup' || unitLower == 'cups') {
      final ml = value * 236.588;
      if (ml >= 1000) {
        final liters = ml / 1000;
        return '${liters.toStringAsFixed(2)} L';
      }
      return '${ml.toStringAsFixed(0)} ml';
    }
    
    if (unitLower == 'tbsp' || unitLower == 'tablespoon' || unitLower == 'tablespoons') {
      final ml = value * 14.7868;
      return '${ml.toStringAsFixed(0)} ml';
    }
    
    if (unitLower == 'tsp' || unitLower == 'teaspoon' || unitLower == 'teaspoons') {
      final ml = value * 4.92892;
      return '${ml.toStringAsFixed(0)} ml';
    }
    
    // Length conversions (less common in recipes)
    if (unitLower == 'in' || unitLower == 'inch' || unitLower == 'inches') {
      return '${(value * 2.54).toStringAsFixed(1)} cm';
    }
    if (unitLower == 'ft' || unitLower == 'foot' || unitLower == 'feet') {
      return '${(value * 0.3048).toStringAsFixed(2)} m';
    }
    
    // If unit not recognized, return original
    return '$value $unit';
  }

  /// Convert a list of ingredients for new servings and/or unit
  List<RecipeIngredient> convertIngredients({
    required List<RecipeIngredient> ingredients,
    required int originalServings,
    required int newServings,
    required MeasurementUnit originalUnit,
    required MeasurementUnit newUnit,
  }) {
    return ingredients.map((ingredient) {
      // First scale for servings
      String convertedAmount = convertAmountForServings(
        ingredient.amount,
        originalServings,
        newServings,
      );

      // Then convert unit if needed (always convert if units differ)
      if (originalUnit != newUnit) {
        final unitConverted = convertAmountForUnit(
          convertedAmount,
          originalUnit,
          newUnit,
        );
        // Use converted amount (even if same, to ensure consistency)
        convertedAmount = unitConverted;
      }

      return ingredient.copyWith(amount: convertedAmount);
    }).toList();
  }
}
