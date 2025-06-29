import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFFF7931E);
  static const Color accent = Color(0xFFFFD23F);
  
  // Couleurs de fond - Mode clair
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Couleurs de fond - Mode sombre
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackgroundDark = Color(0xFF2D2D2D);
  
  // Couleurs de texte - Mode clair
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Couleurs de texte - Mode sombre
  static const Color textPrimaryDark = Color(0xFFE5E5E5);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiaryDark = Color(0xFF808080);
  
  // Couleurs d'état
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Couleurs de bordure
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFF404040);
  
  // Couleurs d'ombre
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x40000000);

  // Méthodes pour obtenir les couleurs selon le thème
  static Color getBackground(bool isDark) => isDark ? backgroundDark : background;
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surface;
  static Color getCardBackground(bool isDark) => isDark ? cardBackgroundDark : cardBackground;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondary;
  static Color getTextTertiary(bool isDark) => isDark ? textTertiaryDark : textTertiary;
  static Color getBorder(bool isDark) => isDark ? borderDark : border;
  static Color getShadow(bool isDark) => isDark ? shadowDark : shadow;
}