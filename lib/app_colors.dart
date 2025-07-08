import 'package:flutter/material.dart';

/// Custom color scheme based on the beautiful palette provided
/// This provides a centralized place to manage all app colors and ensures consistency
class AppColors {
  // Main palette colors
  static const Color champagnePink = Color(0xFFFFE2D1);  // Light warm background
  static const Color nyanza = Color(0xFFE1F0C4);         // Light green accent
  static const Color cambridgeBlue = Color(0xFF6BAB90);  // Primary teal
  static const Color viridian = Color(0xFF55917F);       // Darker teal
  static const Color eggplant = Color(0xFF5E4C5A);       // Dark purple text

  // Semantic colors
  static const Color primary = cambridgeBlue;
  static const Color primaryDark = viridian;
  static const Color surface = champagnePink;
  static const Color accent = nyanza;
  static const Color textDark = eggplant;
  static const Color textLight = Colors.white;

  // Success colors (keeping green theme)
  static const Color success = Color(0xFF99C2A2);
  static const Color successBackground = Color(0xFFF8FDF5);

  // Error colors (soft red to match palette)
  static const Color error = Color(0xFFE57373);
  static const Color errorBackground = Color(0xFFFFEBEE);

  // Gradient combinations
  static const List<Color> primaryGradient = [cambridgeBlue, viridian];
  static const List<Color> backgroundGradient = [champagnePink, nyanza];
  static const List<Color> cardGradient = [Colors.white, champagnePink];
  static const List<Color> accentGradient = [nyanza, champagnePink];

  // Shadow colors - using withValues instead of withOpacity for modern Flutter
  static Color primaryShadow = cambridgeBlue.withValues(alpha: 0.3);
  static Color cardShadow = Colors.black.withValues(alpha: 0.08);
  static Color softShadow = Colors.black.withValues(alpha: 0.06);
  
  // Utility methods for creating color variations
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Get colors with specific alpha values
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }
}
