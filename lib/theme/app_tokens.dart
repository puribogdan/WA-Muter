import 'package:flutter/material.dart';

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color background;
  final Color cardSurface;
  final Color secondarySurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color primaryAccent;
  final Color success;
  final Color inactiveIcon;

  const AppColorTokens({
    required this.background,
    required this.cardSurface,
    required this.secondarySurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.primaryAccent,
    required this.success,
    required this.inactiveIcon,
  });

  static const light = AppColorTokens(
    background: Color(0xFFF6F7FB),
    cardSurface: Color(0xFFFFFFFF),
    secondarySurface: Color(0xFFF1F3F7),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    outline: Color(0xFFE5E7EB),
    primaryAccent: Color(0xFF2563EB),
    success: Color(0xFF22C55E),
    inactiveIcon: Color(0xFF9CA3AF),
  );

  static const dark = AppColorTokens(
    background: Color(0xFF0B1220),
    cardSurface: Color(0xFF111827),
    secondarySurface: Color(0xFF0F172A),
    textPrimary: Color(0xFFE5E7EB),
    textSecondary: Color(0xFF9CA3AF),
    outline: Color(0xFF1F2937),
    primaryAccent: Color(0xFF3B82F6),
    success: Color(0xFF3B82F6),
    inactiveIcon: Color(0xFF64748B),
  );

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? cardSurface,
    Color? secondarySurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? primaryAccent,
    Color? success,
    Color? inactiveIcon,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      cardSurface: cardSurface ?? this.cardSurface,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      outline: outline ?? this.outline,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      success: success ?? this.success,
      inactiveIcon: inactiveIcon ?? this.inactiveIcon,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      secondarySurface: Color.lerp(secondarySurface, other.secondarySurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      inactiveIcon: Color.lerp(inactiveIcon, other.inactiveIcon, t)!,
    );
  }
}

class AppRadii {
  static const double card = 16;
  static const double button = 14;
  static const double pill = 999;
}

class AppSpacing {
  static const double pagePadding = 16;
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 16);
  static const double cardGap = 12;
  static const double rowGap = 10;
}

class AppTypography {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle rowPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle rowSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );
}

extension AppTokenContext on BuildContext {
  AppColorTokens get tokens => Theme.of(this).extension<AppColorTokens>()!;
}
