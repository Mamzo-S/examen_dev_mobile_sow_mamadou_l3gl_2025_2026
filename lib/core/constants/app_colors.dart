import 'package:flutter/material.dart';

/**
 * Palette de couleur de l'application SunuTask
 */
class AppColors {
  AppColors._(); // Constructeur privé pour empecher l'instanciation

  //========= Couleurs principales ==============
  //
  /**
   * Le format hexadecimal se decompose ainsi:
   * - 0x : Prefixe hexadecimale en Dart
   * - FF: Opacite(FF =100%, 80 = 50%)
   * - 293ED: Code couleur RGB(Rouge-Vert-Bleu)
   */
  static const Color primary = Color(0xFF0293ED);
  static const Color primaryLight = Color(0xFF64BBF1);
  static const Color primaryDark = Color(0xFF03436D);

  //========= Palettes UI ==============

  /// Palette de couleurs lors de la creation d'un projet.
  static const List<Color> projectPalette = [
    primary,
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
  ];

  //========= Couleurs secondaires ==============

  static const Color secondary = Color(0xFF61E561);
  static const Color secondaryLight = Color(0xFF41F246);
  static const Color secondaryDark = Color(0xFF05412B);
  static const Color white = Color(0xFFFFFFFF);

  //========= Couleurs neutres ==============

  /// Fond de l'application
  static const Color background = Color(0xFFE2DEDE);

  /// Fond des cartes et surfaces
  static const Color surface = Color(0xFFFFFFFF);

  /// Texte principale
  static const Color textPrimary = Color(0xFF263B4D);

  /// Texte secondaire
  static const Color textSecondary = Color(0xFF5C96C2);

  /// Texte desactive
  static const Color textDisable = Color(0xFF919194);

  /// Bordures et separateurs
  static const Color border = Color(0xFFCECECE);

  //========= Couleurs neutres ==============

  /// Succes - Vert
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFC8FFDB);

  /// Erreur - Rouge
  static const Color error = Color(0xFFE90000);
  static const Color errorLight = Color(0xFFFBADAD);

  /// Avertissement - Orange
  static const Color warning = Color(0xFFD54F04);
  static const Color warningLight = Color(0xFFF7A071);

  /// Information - Bleu
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF7EAAF1);

// ============== Couleurs des priorites ==============

  /// Priorite basse
  static const Color priorityLow = Color(0xFF22C55E);

  /// Priorite moyenne
  static const Color priorityMedium = Color(0xFFF59E0B);

  /// Priorite haute
  static const Color priorityHigh = Color(0xFFEF4444);

  // ============== Couleurs des statuts ==============

  /// A faire
  static const Color statusTodo = Color(0xFF64748B);

  /// En cours
  static const Color statusInProgress = Color(0xFF3B82F6);

  /// Termine
  static const Color statusDone = Color(0xFF22C55E);
}
