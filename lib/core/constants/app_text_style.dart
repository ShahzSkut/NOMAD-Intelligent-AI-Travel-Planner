import 'package:flutter/widgets.dart';
import 'package:nomad_mobile/core/constants/app_color.dart';

// Defines reusable text styles for the application.
class AppTextStyle {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

   static const TextStyle greeting = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle tripCardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const TextStyle tripCardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  static const TextStyle percentageText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );

  static const TextStyle authTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );
}
