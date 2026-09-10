import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';
import 'app_text.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AppColor.background,
        primaryColor: AppColor.primary,
        fontFamily: GoogleFonts.inter().fontFamily,

        colorScheme: const ColorScheme.light(
          primary: AppColor.primary,
          secondary: AppColor.primaryLight,
          surface: AppColor.surface,
          error: AppColor.danger,
          onPrimary: Colors.white,
          onSurface: AppColor.textPrimary,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: AppColor.surface,
          foregroundColor: AppColor.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppText.h2,
          iconTheme: const IconThemeData(color: AppColor.textPrimary),
          systemOverlayStyle: null,
        ),

        cardTheme: CardThemeData(
          color: AppColor.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColor.border),
          ),
        ),

        
        dividerTheme: const DividerThemeData(
          color: AppColor.border,
          thickness: 1,
          space: 1,
        ),

        textTheme: TextTheme(
          displayLarge: AppText.display,
          headlineMedium: AppText.h1,
          titleMedium: AppText.h2,
          titleSmall: AppText.bodyStrong,
          bodyMedium: AppText.body,
          bodySmall: AppText.caption,
          labelLarge: AppText.bodyStrong,
          labelMedium: AppText.label,
          labelSmall: AppText.label,
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColor.border,
            disabledForegroundColor: AppColor.textDisabled,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppText.bodyStrong,
            elevation: 0,
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.primary,
            side: const BorderSide(color: AppColor.border),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppText.bodyStrong,
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primary,
            textStyle: AppText.bodyStrong,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColor.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.danger),
          ),
          labelStyle: AppText.body.copyWith(color: AppColor.textSecondary),
          hintStyle: AppText.body.copyWith(color: AppColor.textDisabled),
          helperStyle: AppText.caption,
          helperMaxLines: 4,
          errorStyle: AppText.caption.copyWith(color: AppColor.danger),
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColor.textPrimary,
          contentTextStyle: AppText.body.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.all(16),
        ),

        dialogTheme: DialogThemeData(
          backgroundColor: AppColor.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: AppText.h2,
          contentTextStyle: AppText.body,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColor.primary,
        ),
      );
}