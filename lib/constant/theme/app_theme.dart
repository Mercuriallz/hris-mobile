import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';
import 'app_text.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  /// Dibangun dari palet yang diberikan, bukan dari [AppColor], karena
  /// MaterialApp menyimpan kedua tema sekaligus — sementara [AppColor] hanya
  /// menunjuk satu palet yang sedang aktif.
  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    TextStyle t(TextStyle s, Color c) => s.copyWith(color: c);

    return ThemeData(
        useMaterial3: false,
        brightness: brightness,
        scaffoldBackgroundColor: p.background,
        primaryColor: p.primary,
        fontFamily: GoogleFonts.inter().fontFamily,

        colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
          primary: p.primary,
          secondary: p.primaryLight,
          surface: p.surface,
          error: p.danger,
          onPrimary: Colors.white,
          onSurface: p.textPrimary,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: p.surface,
          foregroundColor: p.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: t(AppText.h2, p.textPrimary),
          iconTheme: IconThemeData(color: p.textPrimary),
          systemOverlayStyle: null,
        ),

        cardTheme: CardThemeData(
          color: p.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.border),
          ),
        ),

        
        dividerTheme: DividerThemeData(
          color: p.border,
          thickness: 1,
          space: 1,
        ),

        textTheme: TextTheme(
          displayLarge: t(AppText.display, p.textPrimary),
          headlineMedium: t(AppText.h1, p.textPrimary),
          titleMedium: t(AppText.h2, p.textPrimary),
          titleSmall: t(AppText.bodyStrong, p.textPrimary),
          bodyMedium: t(AppText.body, p.textPrimary),
          bodySmall: t(AppText.caption, p.textSecondary),
          labelLarge: t(AppText.bodyStrong, p.textPrimary),
          labelMedium: t(AppText.label, p.textSecondary),
          labelSmall: t(AppText.label, p.textSecondary),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: p.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: p.border,
            disabledForegroundColor: p.textDisabled,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: t(AppText.bodyStrong, p.textPrimary),
            elevation: 0,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: p.primary,
            side: BorderSide(color: p.border),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: t(AppText.bodyStrong, p.textPrimary),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: p.primary,
            textStyle: t(AppText.bodyStrong, p.textPrimary),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: p.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.danger),
          ),
          labelStyle: t(AppText.body, p.textSecondary),
          hintStyle: t(AppText.body, p.textDisabled),
          helperStyle: t(AppText.caption, p.textSecondary),
          helperMaxLines: 4,
          errorStyle: t(AppText.caption, p.danger),
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isDark ? p.border : p.textPrimary,
          contentTextStyle: t(t(AppText.body, p.textPrimary), isDark ? p.textPrimary : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.all(16),
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: t(AppText.h2, p.textPrimary),
          contentTextStyle: t(AppText.body, p.textPrimary),
        ),

        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: p.primary,
        ),
      );
  }
}