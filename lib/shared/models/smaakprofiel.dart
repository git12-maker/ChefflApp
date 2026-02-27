import 'dart:convert';
import 'ingredient.dart';

/// Mondgevoel (Mouthfeel) - one of the universal flavor factors
/// Based on boek_compleet.md: strak (astringent/tight), filmend (coating), droog (dry)
class Mondgevoel {
  const Mondgevoel({
    this.strak = 0.0,
    this.filmend = 0.0,
    this.droog = 0.0,
  });

  /// Strak: samentrekkend (astringent/tight) - from acids, salt, cold, carbonation
  final double strak;

  /// Filmend: leaves a layer in the mouth (coating) - from fats, oils, creamy textures
  final double filmend;

  /// Droog: absorbs moisture (dry) - from starches, crackers, overcooked proteins
  final double droog;

  /// Get the dominant mouthfeel component
  String get dominant {
    if (strak >= filmend && strak >= droog) return 'strak';
    if (filmend >= droog) return 'filmend';
    return 'droog';
  }

  /// Check if mouthfeel is balanced (no single component overwhelming)
  bool get isBalanced {
    final values = [strak, filmend, droog];
    final max = values.reduce((a, b) => a > b ? a : b);
    final sum = values.reduce((a, b) => a + b);
    if (sum == 0) return true;
    final avg = sum / values.length;
    return max - avg < 0.3; // No single component more than 0.3 above average
  }

  /// Calculate strak/filmend ratio for balance analysis
  double get strakFilmendRatio {
    if (filmend == 0) return strak > 0 ? 10.0 : 0.0; // Avoid division by zero
    return strak / filmend;
  }

  factory Mondgevoel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Mondgevoel();
    return Mondgevoel(
      strak: (json['mondgevoel_strak'] as num?)?.toDouble() ?? 
             (json['strak'] as num?)?.toDouble() ?? 0.0,
      filmend: (json['mondgevoel_filmend'] as num?)?.toDouble() ?? 
               (json['filmend'] as num?)?.toDouble() ?? 0.0,
      droog: (json['mondgevoel_droog'] as num?)?.toDouble() ?? 
             (json['droog'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mondgevoel_strak': strak,
        'mondgevoel_filmend': filmend,
        'mondgevoel_droog': droog,
      };

  Mondgevoel operator +(Mondgevoel other) {
    return Mondgevoel(
      strak: strak + other.strak,
      filmend: filmend + other.filmend,
      droog: droog + other.droog,
    );
  }

  Mondgevoel operator /(num divisor) {
    return Mondgevoel(
      strak: strak / divisor,
      filmend: filmend / divisor,
      droog: droog / divisor,
    );
  }

  Mondgevoel operator *(num multiplier) {
    return Mondgevoel(
      strak: strak * multiplier,
      filmend: filmend * multiplier,
      droog: droog * multiplier,
    );
  }
}

/// Smaakrijkdom (Flavor Richness) - one of the universal flavor factors
/// Based on boek_compleet.md: smaakgehalte (intensity/volume) and smaaktype (fris ↔ rijp)
class Smaakrijkdom {
  const Smaakrijkdom({
    this.gehalte = 0.0,
    this.type = 0.5,
  });

  /// Smaakgehalte: flavor intensity/volume (0.0 = low, 1.0 = high)
  final double gehalte;

  /// Smaaktype: flavor type spectrum (0.0 = fris/fresh, 1.0 = rijp/ripe)
  final double type;

  /// Get human-readable type description
  String get typeDescription {
    if (type < 0.3) return 'fris';
    if (type < 0.7) return 'neutraal';
    return 'rijp';
  }

  factory Smaakrijkdom.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Smaakrijkdom();
    return Smaakrijkdom(
      gehalte: (json['smaakgehalte'] as num?)?.toDouble() ?? 0.0,
      type: (json['smaaktype'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'smaakgehalte': gehalte,
        'smaaktype': type,
      };

  Smaakrijkdom operator +(Smaakrijkdom other) {
    return Smaakrijkdom(
      gehalte: gehalte + other.gehalte,
      type: type + other.type,
    );
  }

  Smaakrijkdom operator /(num divisor) {
    return Smaakrijkdom(
      gehalte: gehalte / divisor,
      type: type / divisor,
    );
  }

  Smaakrijkdom operator *(num multiplier) {
    return Smaakrijkdom(
      gehalte: gehalte * multiplier,
      type: type * multiplier,
    );
  }
}

/// Complete Smaakprofiel (Flavor Profile) - combines mondgevoel and smaakrijkdom
/// Based on boek_compleet.md universal flavor factors theory
class Smaakprofiel {
  const Smaakprofiel({
    this.mondgevoel = const Mondgevoel(),
    this.smaakrijkdom = const Smaakrijkdom(),
  });

  final Mondgevoel mondgevoel;
  final Smaakrijkdom smaakrijkdom;

  /// Get human-readable description of the profile
  String get description {
    final mondgevoelDesc = mondgevoel.dominant;
    final typeDesc = smaakrijkdom.typeDescription;
    final gehalteDesc = smaakrijkdom.gehalte > 0.7 
        ? 'intens' 
        : smaakrijkdom.gehalte > 0.4 
            ? 'gematigd' 
            : 'licht';
    
    return '$gehalteDesc, $typeDesc, $mondgevoelDesc';
  }

  factory Smaakprofiel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Smaakprofiel();
    return Smaakprofiel(
      mondgevoel: Mondgevoel.fromJson(json),
      smaakrijkdom: Smaakrijkdom.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
        ...mondgevoel.toJson(),
        ...smaakrijkdom.toJson(),
      };

  Smaakprofiel operator +(Smaakprofiel other) {
    return Smaakprofiel(
      mondgevoel: mondgevoel + other.mondgevoel,
      smaakrijkdom: smaakrijkdom + other.smaakrijkdom,
    );
  }

  Smaakprofiel operator /(num divisor) {
    return Smaakprofiel(
      mondgevoel: mondgevoel / divisor,
      smaakrijkdom: smaakrijkdom / divisor,
    );
  }

  Smaakprofiel operator *(num multiplier) {
    return Smaakprofiel(
      mondgevoel: mondgevoel * multiplier,
      smaakrijkdom: smaakrijkdom * multiplier,
    );
  }
}

/// Ingredient with its smaakprofiel and weight for composition calculation
class IngredientSmaakprofiel {
  const IngredientSmaakprofiel({
    required this.ingredient,
    required this.smaakprofiel,
    this.cookingMethod,
    this.gewicht = 100,
  });

  final Ingredient ingredient;
  final Smaakprofiel smaakprofiel;
  final String? cookingMethod;
  final int gewicht; // Weight for weighted average calculation

  factory IngredientSmaakprofiel.fromJson(Map<String, dynamic> json) {
    return IngredientSmaakprofiel(
      ingredient: Ingredient.fromJson(json),
      smaakprofiel: Smaakprofiel.fromJson(json),
      cookingMethod: json['cooking_method']?.toString(),
      gewicht: (json['gewicht'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
        ...ingredient.toJson(),
        ...smaakprofiel.toJson(),
        'cooking_method': cookingMethod,
        'gewicht': gewicht,
      };
}
