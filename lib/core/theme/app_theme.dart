import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

final class AppTheme {
  const AppTheme._();

  static ThemeData light() => _buildTheme(AppColorSets.light, Brightness.light);

  static ThemeData dark() => _buildTheme(AppColorSets.dark, Brightness.dark);

  static ThemeData _buildTheme(AppColorSet colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: brightness == Brightness.dark
          ? AppPalette.midnightCanvas
          : Colors.white,
      secondary: colors.admin,
      onSecondary: brightness == Brightness.dark
          ? AppPalette.midnightCanvas
          : Colors.white,
      error: colors.error,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      disabledColor: brightness == Brightness.dark
          ? const Color(0xFF73849A)
          : const Color(0xFF94A3B8),
      dividerColor: colors.outline,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: colors.ink,
        height: 1.02,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: colors.ink,
        height: 1.05,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.ink,
        height: 1.12,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colors.ink,
        height: 1.12,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: colors.ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colors.ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.ink,
        height: 1.55,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.inkMuted,
        height: 1.55,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.inkMuted,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.inkMuted,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: colors.inkMuted,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.ink,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.large,
          side: BorderSide(color: colors.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        disabledColor: colors.outline,
        selectedColor: colors.primarySoft,
        secondarySelectedColor: colors.adminSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pill,
          side: BorderSide(color: colors.outlineStrong),
        ),
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: colors.outlineStrong),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceGlassStrong,
        hintStyle: textTheme.bodyMedium,
        helperStyle: textTheme.bodySmall,
        labelStyle: textTheme.labelLarge?.copyWith(color: colors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: colors.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: colors.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.medium,
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryStrong,
          foregroundColor: brightness == Brightness.dark
              ? AppPalette.midnightCanvas
              : Colors.white,
          disabledBackgroundColor: brightness == Brightness.dark
              ? const Color(0xFF2F455C)
              : const Color(0xFFB7CFD8),
          disabledForegroundColor: brightness == Brightness.dark
              ? colors.inkMuted
              : Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.large),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.outlineStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.large),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.admin,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.medium),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceGlassStrong,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xLarge),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: brightness == Brightness.dark ? colors.canvas : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.medium),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.navSurface,
        indicatorColor: colors.primarySoft,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? colors.primary : colors.inkMuted,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceGlassStrong,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
      ),
    );
  }
}
