import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF3EBDE0);
  static const Color primaryOrange = Color(0xFFFAA621);
  static const Color accentGreen = Color(0xFFA7D820);

  static const Color ongoingBlue = Color(0xFF379ae6);
  static const Color plannedOrange = Color(0xFFefb034);
  static const Color completedGreen = Color(0xFF1dd75b);

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color primaryText = Color(0xFF1C1C1E);
  static const Color secondaryText = Color(0xFF8E8E93);
  static const Color borderColor = Color(0xFFE5E5EA);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryOrange],
    begin: Alignment(-1.0, 0.3),
    end: Alignment(1.0, -0.3),
  );
}