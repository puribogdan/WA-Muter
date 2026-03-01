import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        tokens: AppColorTokens.light,
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        tokens: AppColorTokens.dark,
      );

  // Backward-compatible aliases used by current app entrypoints.
  static ThemeData lightTheme() => light();
  static ThemeData darkTheme() => dark();

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColorTokens tokens,
  }) {
    final isDark = brightness == Brightness.dark;
    const onAccent = Colors.white;
    final navBg = isDark ? tokens.surface2 : AppColors.lightPrimary;
    final navFg = isDark ? tokens.primary : Colors.white;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: tokens.accent,
      brightness: brightness,
    );

    final colorScheme = baseScheme.copyWith(
      primary: tokens.accent,
      onPrimary: onAccent,
      secondary: tokens.accentLight,
      onSecondary: AppColors.lightPrimary,
      tertiary: tokens.success,
      onTertiary: Colors.white,
      error: tokens.danger,
      onError: isDark ? AppColors.darkBackground : Colors.white,
      surface: tokens.surface,
      onSurface: tokens.primary,
      surfaceTint: Colors.transparent,
      outline: tokens.divider,
      outlineVariant: tokens.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.lightPrimary,
      onInverseSurface: isDark ? AppColors.lightPrimary : AppColors.lightSurface,
      inversePrimary: tokens.accentLight,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    final textTheme = baseTextTheme.copyWith(
      displaySmall: AppTypography.displayTitle.copyWith(color: tokens.primary),
      titleLarge: AppTypography.displayTitle.copyWith(color: tokens.primary),
      titleMedium: AppTypography.sectionTitle.copyWith(color: tokens.primary),
      titleSmall: AppTypography.cardTitle.copyWith(color: tokens.primary),
      bodyLarge: AppTypography.body.copyWith(color: tokens.primary),
      bodyMedium: AppTypography.secondaryBody.copyWith(color: tokens.secondary),
      bodySmall: AppTypography.micro.copyWith(color: tokens.muted),
      labelLarge: AppTypography.bodyStrong.copyWith(color: tokens.primary),
      labelMedium:
          AppTypography.secondaryBodyStrong.copyWith(color: tokens.secondary),
      labelSmall: AppTypography.micro.copyWith(color: tokens.muted),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: tokens.divider),
    );

    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: tokens.accent, width: 1.4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      dividerColor: tokens.divider,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.primary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.displayTitle.copyWith(color: tokens.primary),
        iconTheme: IconThemeData(color: tokens.primary),
        actionsIconTheme: IconThemeData(color: tokens.primary),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        margin: EdgeInsets.zero,
        elevation: isDark ? 1.5 : 2.0,
        shadowColor: (isDark ? AppShadows.softDark : AppShadows.softLight).color,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.listRow),
        ),
        tileColor: tokens.surface,
        contentPadding: AppSpacing.listItemPadding,
        iconColor: tokens.secondary,
        textColor: tokens.primary,
        subtitleTextStyle:
            AppTypography.secondaryBody.copyWith(color: tokens.secondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: AppTypography.secondaryBody.copyWith(color: tokens.muted),
        prefixIconColor: tokens.muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.divider.withOpacity(0.7)),
        ),
        focusedBorder: focusedInputBorder,
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: focusedInputBorder.copyWith(
          borderSide: BorderSide(color: tokens.danger, width: 1.4),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: navFg,
        unselectedItemColor: navFg.withOpacity(0.6),
        selectedLabelStyle: AppTypography.micro.copyWith(color: navFg),
        unselectedLabelStyle:
            AppTypography.micro.copyWith(color: navFg.withOpacity(0.6)),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        height: 72,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.accent.withOpacity(isDark ? 0.16 : 0.22),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? navFg : navFg.withOpacity(0.6),
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.micro.copyWith(
            color: selected ? navFg : navFg.withOpacity(0.6),
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.accent,
        foregroundColor: onAccent,
        elevation: isDark ? 6 : 8,
        focusElevation: isDark ? 8 : 10,
        hoverElevation: isDark ? 8 : 10,
        highlightElevation: isDark ? 10 : 12,
        disabledElevation: 0,
        shape: const CircleBorder(),
        extendedTextStyle: AppTypography.bodyStrong.copyWith(color: onAccent),
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.accent;
          return isDark ? tokens.divider : const Color(0xFFD1D5DB);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.accent;
          return Colors.transparent;
        }),
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: tokens.accent,
        brightness: brightness,
        labelStyle: AppTypography.micro.copyWith(color: tokens.muted),
      ).copyWith(
        backgroundColor: isDark ? const Color(0xFF1A1F1B) : AppColors.lightChartGrid,
        disabledColor: isDark ? const Color(0xFF1A1F1B) : AppColors.lightChartGrid,
        selectedColor: tokens.accent.withOpacity(isDark ? 0.20 : 0.16),
        secondarySelectedColor: tokens.accent.withOpacity(isDark ? 0.20 : 0.16),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.micro.copyWith(color: tokens.muted),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.surface),
          foregroundColor: WidgetStatePropertyAll(tokens.primary),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          shadowColor: WidgetStatePropertyAll(
            (isDark ? AppShadows.softDark : AppShadows.softLight).color,
          ),
          elevation: const WidgetStatePropertyAll(1),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return tokens.accent.withOpacity(0.10);
            }
            return null;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: onAccent,
          textStyle: AppTypography.bodyStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: AppTypography.bodyStrong,
          side: BorderSide(color: tokens.divider),
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          textStyle: AppTypography.bodyStrong,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}
