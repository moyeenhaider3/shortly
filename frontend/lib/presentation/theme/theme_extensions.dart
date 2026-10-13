import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

extension ThemeTokens on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get text => Theme.of(this).extension<AppTypography>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
