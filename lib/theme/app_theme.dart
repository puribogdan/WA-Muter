import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData lightTheme() => _buildTheme(
        brightness: Brightness.light,
        tokens: AppColorTokens.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF2563EB),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF2563EB),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFB91C1C),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF111827),
        ),
      );

  static ThemeData darkTheme() => _buildTheme(
        brightness: Brightness.dark,
        tokens: AppColorTokens.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF3B82F6),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF3B82F6),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFF87171),
          onError: Color(0xFF0B1220),
          surface: Color(0xFF111827),
          onSurface: Color(0xFFE5E7EB),
        ),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColorTokens tokens,
    required ColorScheme colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      fontFamily: 'Inter',
      extensions: <ThemeExtension<dynamic>>[tokens],
      dividerColor: tokens.outline,
      textTheme: TextTheme(
        titleLarge: AppTypography.title.copyWith(color: tokens.textPrimary),
        titleMedium: AppTypography.cardTitle.copyWith(color: tokens.textPrimary),
        titleSmall:
            AppTypography.sectionHeader.copyWith(color: tokens.textPrimary),
        bodyLarge: AppTypography.rowPrimary.copyWith(color: tokens.textPrimary),
        bodyMedium:
            AppTypography.rowSecondary.copyWith(color: tokens.textSecondary),
        bodySmall:
            AppTypography.cardSubtitle.copyWith(color: tokens.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.title.copyWith(
          fontSize: 28,
          color: tokens.textPrimary,
        ),
        iconTheme: IconThemeData(color: tokens.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: tokens.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.cardSurface,
        indicatorColor: tokens.secondarySurface,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.primaryAccent : tokens.inactiveIcon,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.cardSubtitle.copyWith(
            color: selected ? tokens.primaryAccent : tokens.inactiveIcon,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return tokens.inactiveIcon;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? tokens.primaryAccent : tokens.success;
          }
          return tokens.outline;
        }),
      ),
    );
  }
}
