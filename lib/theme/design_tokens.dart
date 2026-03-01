import 'package:flutter/material.dart';

/// Raw design tokens (single source of truth) for the Mute Scheduler visual theme.
class AppColors {
  AppColors._();

  // Light theme (exact tokens)
  static const Color lightPrimary = Color(0xFF1A1A1A);
  static const Color lightSecondary = Color(0xFF6B7280);
  static const Color lightAccent = Color(0xFFA3B836);
  static const Color lightAccentLight = Color(0xFFC5D95F);
  static const Color lightBackground = Color(0xFFF2F4F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightMuted = Color(0xFF9CA3AF);
  static const Color lightChartGrid = Color(0xFFF3F4F6);
  static const Color lightSuccess = Color(0xFF22C55E);
  static const Color lightWarning = Color(0xFFCA8A04);
  static const Color lightWarningContainer = Color(0xFFFFFBEB);
  static const Color lightDanger = Color(0xFFEF4444);
  static const Color lightDangerContainer = Color(0xFFFEF2F2);

  // Dark theme (derived, consistent)
  static const Color darkBackground = Color(0xFF0B0F0A);
  static const Color darkSurface = Color(0xFF111612);
  static const Color darkSurface2 = Color(0xFF151B16);
  static const Color darkPrimary = Color(0xFFF3F4F5);
  static const Color darkSecondary = Color(0xFFA7B0A9);
  static const Color darkMuted = Color(0xFF7D877F);
  static const Color darkDivider = Color(0xFF232A24);
  static const Color darkAccent = lightAccent;
  static const Color darkAccentLight = lightAccentLight;
  static const Color darkDanger = Color(0xFFFF6B6B);
  static const Color darkDangerContainer = Color(0xFF2A1717);
  static const Color darkWarning = Color(0xFFD6A700);
  static const Color darkWarningContainer = Color(0xFF2A240F);
  static const Color darkSuccess = lightSuccess;
  static const Color darkSuccessContainer = Color(0xFF0F2416);
  static const Color darkChartGrid = Color(0xFF1A1F1B);
}

class AppShadows {
  AppShadows._();

  // Light (exact approximations requested)
  static const BoxShadow softLight = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 20,
    spreadRadius: -2,
    color: Color(0x0D000000), // 0.05
  );
  static const BoxShadow floatLight = BoxShadow(
    offset: Offset(0, 10),
    blurRadius: 30,
    spreadRadius: -5,
    color: Color(0x1A000000), // 0.10
  );
  static const BoxShadow accentGlowLight = BoxShadow(
    offset: Offset(0, 10),
    blurRadius: 15,
    spreadRadius: -3,
    color: Color(0x4DA3B836), // accent @ 0.30
  );

  // Dark (subtler blur, stronger alpha)
  static const BoxShadow softDark = BoxShadow(
    offset: Offset(0, 3),
    blurRadius: 14,
    spreadRadius: -3,
    color: Color(0x59000000), // 0.35
  );
  static const BoxShadow floatDark = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 20,
    spreadRadius: -6,
    color: Color(0x73000000), // 0.45
  );
  static const BoxShadow accentGlowDark = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 14,
    spreadRadius: -4,
    color: Color(0x40A3B836), // accent @ 0.25
  );

  static List<BoxShadow> soft(bool isDark) => [isDark ? softDark : softLight];
  static List<BoxShadow> floating(bool isDark) =>
      [isDark ? floatDark : floatLight];
  static List<BoxShadow> accentGlow(bool isDark) =>
      [isDark ? accentGlowDark : accentGlowLight];
}

class AppRadii {
  AppRadii._();

  static const double card = 24;
  static const double listRow = 16;
  static const double input = 16;
  static const double pill = 999;
  static const double bottomNav = 32;

  static const double button40 = 40;
  static const double button44 = 44;
  static const double button56 = 56;
}

class AppSpacing {
  AppSpacing._();

  static const double pagePadding = 24;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  static const double section = 24;
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap24 = 24;

  // Backward-compatible aliases used in existing screens.
  static const double cardGap = gap12;
  static const double rowGap = gap8;
}

class AppTypography {
  AppTypography._();

  // Named scale requested
  static const TextStyle displayTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.25,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.3,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle secondaryBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle secondaryBodyStrong = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  static const TextStyle micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    fontFamily: 'Inter',
    fontFamilyFallback: ['Roboto'],
  );

  // Backward-compatible aliases currently used around the app.
  static const TextStyle title = displayTitle;
  static const TextStyle cardSubtitle = secondaryBodyStrong;
  static const TextStyle sectionHeader = sectionTitle;
  static const TextStyle rowPrimary = bodyStrong;
  static const TextStyle rowSecondary = secondaryBody;
}
