import 'smaakprofiel.dart';

/// Balance analysis result
/// Identifies imbalances and missing elements in a smaakprofiel
class BalansAnalyse {
  const BalansAnalyse({
    required this.smaakprofiel,
    required this.isBalanced,
    required this.strakFilmendRatio,
    required this.frisRijpBalans,
    required this.ontbrekendeElementen,
    required this.suggesties,
    this.beschrijving,
  });

  final Smaakprofiel smaakprofiel;
  final bool isBalanced;
  final double strakFilmendRatio;
  final double frisRijpBalans; // 0.0 = te fris, 1.0 = te rijp, 0.4-0.6 = gebalanceerd
  final List<OntbrekendElement> ontbrekendeElementen;
  final List<String> suggesties;
  final String? beschrijving;

  /// Get human-readable balance description
  String get balanceDescription {
    if (isBalanced) {
      return 'Goed gebalanceerd gerecht';
    }

    final issues = <String>[];
    
    if (strakFilmendRatio < 0.3) {
      issues.add('te filmend/romig');
    } else if (strakFilmendRatio > 3.0) {
      issues.add('te strak/zuur');
    }

    if (frisRijpBalans < 0.3) {
      issues.add('te fris');
    } else if (frisRijpBalans > 0.7) {
      issues.add('te rijp');
    }

    if (issues.isEmpty) {
      return 'Goed gebalanceerd gerecht';
    }

    return 'Gerecht is ${issues.join(' en ')}';
  }
}

/// Missing element in the composition
enum OntbrekendElementType {
  strak, // Missing astringent/tight element
  filmend, // Missing coating/rich element
  droog, // Missing dry/crispy element
  fris, // Missing fresh element
  rijp, // Missing ripe element
  smaakgehalte, // Missing flavor intensity
}

/// A missing element with priority and suggestion
class OntbrekendElement {
  const OntbrekendElement({
    required this.type,
    required this.reason,
    required this.priority,
    this.suggestie,
  });

  final OntbrekendElementType type;
  final String reason;
  final MissingPriority priority;
  final String? suggestie; // Suggested ingredient category or type
}

/// Priority level for missing elements
enum MissingPriority {
  high,
  medium,
  low,
}

/// Balance analyzer
/// Analyzes smaakprofiel and identifies imbalances
class BalansAnalyzer {
  /// Analyze balance of a smaakprofiel
  static BalansAnalyse analyseer(Smaakprofiel profiel) {
    final strakFilmendRatio = profiel.mondgevoel.strakFilmendRatio;
    final frisRijpBalans = profiel.smaakrijkdom.type;

    // Check for imbalances
    final ontbrekendeElementen = <OntbrekendElement>[];
    final suggesties = <String>[];

    // Strak/Filmend balance check
    bool isBalanced = true;

    if (strakFilmendRatio < 0.3) {
      // Too filmend/romig - needs strak element
      isBalanced = false;
      ontbrekendeElementen.add(const OntbrekendElement(
        type: OntbrekendElementType.strak,
        reason: 'Gerecht is te filmend/romig. Voeg iets zuurs of fris toe voor balans.',
        priority: MissingPriority.high,
        suggestie: 'zuur, citrus, azijn',
      ));
      suggesties.add('Voeg iets zuurs toe (citroen, azijn, tomaat)');
    } else if (strakFilmendRatio > 3.0) {
      // Too strak/zuur - needs filmend element
      isBalanced = false;
      ontbrekendeElementen.add(const OntbrekendElement(
        type: OntbrekendElementType.filmend,
        reason: 'Gerecht is te strak/zuur. Voeg iets romigs toe voor balans.',
        priority: MissingPriority.high,
        suggestie: 'boter, room, olijfolie',
      ));
      suggesties.add('Voeg iets romigs toe (boter, room, olijfolie)');
    }

    // Fris/Rijp balance check
    if (frisRijpBalans < 0.2) {
      // Too fris - needs rijp element
      isBalanced = false;
      ontbrekendeElementen.add(const OntbrekendElement(
        type: OntbrekendElementType.rijp,
        reason: 'Gerecht is zeer fris. Voeg iets rijps toe voor diepte.',
        priority: MissingPriority.medium,
        suggestie: 'geroosterd, karamel, umami',
      ));
      suggesties.add('Voeg iets rijps toe (geroosterde groenten, umami-rijke ingrediënten)');
    } else if (frisRijpBalans > 0.8) {
      // Too rijp - needs fris element
      isBalanced = false;
      ontbrekendeElementen.add(const OntbrekendElement(
        type: OntbrekendElementType.fris,
        reason: 'Gerecht is zeer rijp. Voeg iets fris toe voor verfrissing.',
        priority: MissingPriority.medium,
        suggestie: 'citrus, groene kruiden, rauwe groenten',
      ));
      suggesties.add('Voeg iets fris toe (citrus, groene kruiden, rauwe groenten)');
    }

    // Smaakgehalte check
    if (profiel.smaakrijkdom.gehalte < 0.3) {
      ontbrekendeElementen.add(const OntbrekendElement(
        type: OntbrekendElementType.smaakgehalte,
        reason: 'Gerecht heeft weinig smaakintensiteit. Voeg smaakrijke ingrediënten toe.',
        priority: MissingPriority.low,
        suggestie: 'kruiden, specerijen, umami',
      ));
      suggesties.add('Voeg smaakrijke ingrediënten toe (kruiden, specerijen, umami)');
    }

    // Droog element check (optional, for texture variety)
    if (profiel.mondgevoel.droog < 0.1 && profiel.mondgevoel.strak < 0.3 && profiel.mondgevoel.filmend < 0.3) {
      // Very neutral, could use some texture
      ontbrekendeElementen.add(const OntbrekendElement(
        type: OntbrekendElementType.droog,
        reason: 'Gerecht mist textuurvariatie. Voeg iets knapperigs toe.',
        priority: MissingPriority.low,
        suggestie: 'krokant, knapperig, geroosterd',
      ));
    }

    final beschrijving = _generateBeschrijving(profiel, isBalanced);

    return BalansAnalyse(
      smaakprofiel: profiel,
      isBalanced: isBalanced,
      strakFilmendRatio: strakFilmendRatio,
      frisRijpBalans: frisRijpBalans,
      ontbrekendeElementen: ontbrekendeElementen,
      suggesties: suggesties,
      beschrijving: beschrijving,
    );
  }

  /// Generate human-readable description
  static String _generateBeschrijving(Smaakprofiel profiel, bool isBalanced) {
    if (isBalanced) {
      final typeDesc = profiel.smaakrijkdom.typeDescription;
      final gehalteDesc = profiel.smaakrijkdom.gehalte > 0.7 
          ? 'intens' 
          : profiel.smaakrijkdom.gehalte > 0.4 
              ? 'gematigd' 
              : 'licht';
      
      return 'Goed gebalanceerd gerecht met $gehalteDesc, $typeDesc smaakprofiel.';
    }

    final issues = <String>[];
    
    if (profiel.mondgevoel.strakFilmendRatio < 0.3) {
      issues.add('romig/filmend');
    } else if (profiel.mondgevoel.strakFilmendRatio > 3.0) {
      issues.add('strak/zuur');
    }

    if (profiel.smaakrijkdom.type < 0.3) {
      issues.add('fris');
    } else if (profiel.smaakrijkdom.type > 0.7) {
      issues.add('rijp');
    }

    if (issues.isEmpty) {
      return 'Gerecht heeft een gebalanceerd smaakprofiel.';
    }

    return 'Gerecht is ${issues.join(' en ')}. Overweeg toevoeging van tegenovergestelde elementen voor balans.';
  }
}
