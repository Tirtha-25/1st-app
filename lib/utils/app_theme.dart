import 'package:flutter/material.dart';

/// Unified color theme for the entire app (matching weather aesthetic)
class AppTheme {
  // Primary blues (weather-inspired)
  static const Color primary = Color(0xFF1488CC);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Accent
  static const Color accent = Color(0xFF26C6DA);

  // Backgrounds
  static const Color bgDark = Color(0xFF0A0E21);
  static const Color bgCard = Color(0xFF111328);
  static const Color bgCardHover = Color(0xFF1A1D3A);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8D8E98);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  // Category selected chip
  static const Color chipSelected = Color(0xFF1488CC);

  // Gradients
  static const List<Color> headerGradient = [
    Color(0xFF0A0E21),
    Color(0xFF111328),
  ];

  // Source accent colors (for variety in news cards)
  static const List<Color> sourceColors = [
    Color(0xFF42A5F5),
    Color(0xFF26C6DA),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFFAB47BC),
    Color(0xFFEC407A),
    Color(0xFF7E57C2),
    Color(0xFF29B6F6),
  ];

  static Color getSourceColor(String source) {
    return sourceColors[source.hashCode.abs() % sourceColors.length];
  }
}
