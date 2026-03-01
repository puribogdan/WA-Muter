import 'package:flutter/material.dart';

import 'design_tokens.dart';
export 'design_tokens.dart';

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color surface;
  final Color surface2;
  final Color divider;
  final Color muted;
  final Color chartGrid;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;

  const AppColorTokens({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.divider,
    required this.muted,
    required this.chartGrid,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
  });

  static const light = AppColorTokens(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightSecondary,
    accent: AppColors.lightAccent,
    accentLight: AppColors.lightAccentLight,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surface2: AppColors.lightChartGrid,
    divider: AppColors.lightDivider,
    muted: AppColors.lightMuted,
    chartGrid: AppColors.lightChartGrid,
    success: AppColors.lightSuccess,
    successContainer: Color(0xFFF0FDF4),
    warning: AppColors.lightWarning,
    warningContainer: AppColors.lightWarningContainer,
    danger: AppColors.lightDanger,
    dangerContainer: AppColors.lightDangerContainer,
  );

  static const dark = AppColorTokens(
    primary: AppColors.darkPrimary,
    secondary: AppColors.darkSecondary,
    accent: AppColors.darkAccent,
    accentLight: AppColors.darkAccentLight,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surface2: AppColors.darkSurface2,
    divider: AppColors.darkDivider,
    muted: AppColors.darkMuted,
    chartGrid: AppColors.darkChartGrid,
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    danger: AppColors.darkDanger,
    dangerContainer: AppColors.darkDangerContainer,
  );

  // Backward-compatible aliases for existing screens/widgets.
  Color get textPrimary => primary;
  Color get textSecondary => secondary;
  Color get cardSurface => surface;
  Color get secondarySurface => surface2;
  Color get outline => divider;
  Color get primaryAccent => accent;
  Color get inactiveIcon => muted;

  @override
  AppColorTokens copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? accentLight,
    Color? background,
    Color? surface,
    Color? surface2,
    Color? divider,
    Color? muted,
    Color? chartGrid,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
  }) {
    return AppColorTokens(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      divider: divider ?? this.divider,
      muted: muted ?? this.muted,
      chartGrid: chartGrid ?? this.chartGrid,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
    );
  }
}

extension AppTokenContext on BuildContext {
  AppColorTokens get tokens => Theme.of(this).extension<AppColorTokens>()!;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}

/// Reusable visual helpers for incremental adoption on existing widgets.
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card(BuildContext context) {
    final tokens = context.tokens;
    return BoxDecoration(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      boxShadow: AppShadows.soft(context.isDarkTheme),
    );
  }

  static BoxDecoration listRow(
    BuildContext context, {
    bool disabled = false,
  }) {
    final tokens = context.tokens;
    return BoxDecoration(
      color: disabled ? tokens.surface.withOpacity(0.7) : tokens.surface,
      borderRadius: BorderRadius.circular(AppRadii.listRow),
      boxShadow: AppShadows.soft(context.isDarkTheme),
    );
  }

  static BoxDecoration searchFieldContainer(
    BuildContext context, {
    bool focused = false,
  }) {
    final tokens = context.tokens;
    return BoxDecoration(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(AppRadii.input),
      boxShadow: [
        ...AppShadows.soft(context.isDarkTheme),
        if (focused)
          BoxShadow(
            offset: const Offset(0, 0),
            blurRadius: 12,
            spreadRadius: 0,
            color: tokens.accent.withOpacity(0.20),
          ),
      ],
    );
  }

  static BoxDecoration iconButtonCircle(BuildContext context) {
    final tokens = context.tokens;
    return BoxDecoration(
      color: tokens.surface,
      shape: BoxShape.circle,
      boxShadow: AppShadows.soft(context.isDarkTheme),
    );
  }

  static BoxDecoration pill(BuildContext context) {
    final tokens = context.tokens;
    return BoxDecoration(
      color: context.isDarkTheme ? tokens.chartGrid : AppColors.lightChartGrid,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    );
  }

  static BoxDecoration statusBubble(
    BuildContext context, {
    required Color bg,
  }) {
    return BoxDecoration(
      color: bg,
      shape: BoxShape.circle,
    );
  }
}

class AppInputStyles {
  AppInputStyles._();

  static InputDecoration search(
    BuildContext context, {
    required String hintText,
    Widget? prefixIcon,
  }) {
    final tokens = context.tokens;
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: tokens.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: tokens.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: tokens.accent, width: 1.4),
      ),
    );
  }
}
