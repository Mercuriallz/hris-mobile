import 'package:flutter/material.dart';

/// Satu set warna lengkap untuk satu mode tampilan.
class AppPalette {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primarySurface;

  final Color background;
  final Color surface;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color danger;
  final Color dangerSurface;
  final Color info;
  final Color infoSurface;

  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primarySurface,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.danger,
    required this.dangerSurface,
    required this.info,
    required this.infoSurface,
  });

  static const light = AppPalette(
    primary: Color(0xFF1565C0),
    primaryDark: Color(0xFF0D47A1),
    primaryLight: Color(0xFF42A5F5),
    primarySurface: Color(0xFFE8F1FB),
    background: Color(0xFFF4F6F9),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE3E8EF),
    textPrimary: Color(0xFF1A2027),
    textSecondary: Color(0xFF5A6672),
    textDisabled: Color(0xFF9AA4B0),
    success: Color(0xFF2E7D32),
    successSurface: Color(0xFFE8F5E9),
    warning: Color(0xFFEF6C00),
    warningSurface: Color(0xFFFFF3E0),
    danger: Color(0xFFC62828),
    dangerSurface: Color(0xFFFFEBEE),
    info: Color(0xFF0277BD),
    infoSurface: Color(0xFFE1F5FE),
  );

  /// Mode gelap bukan sekadar warna terang yang dibalik. Warna status dibuat
  /// lebih terang supaya tetap terbaca di atas latar gelap, dan permukaannya
  /// diturunkan jadi nada gelap yang hanya sedikit berwarna — permukaan
  /// berwarna pekat di layar gelap terasa menyilaukan.
  static const dark = AppPalette(
    primary: Color(0xFF4C8DF6),
    primaryDark: Color(0xFF0B3A82),
    primaryLight: Color(0xFF90CAF9),
    primarySurface: Color(0xFF16263D),
    background: Color(0xFF0F1419),
    surface: Color(0xFF1A2027),
    border: Color(0xFF2A333D),
    textPrimary: Color(0xFFE6EAF0),
    textSecondary: Color(0xFF9AA6B2),
    textDisabled: Color(0xFF5F6B78),
    success: Color(0xFF66BB6A),
    successSurface: Color(0xFF1B2E1F),
    warning: Color(0xFFFFA040),
    warningSurface: Color(0xFF33261A),
    danger: Color(0xFFEF5350),
    dangerSurface: Color(0xFF3A1D1F),
    info: Color(0xFF4FC3F7),
    infoSurface: Color(0xFF15303D),
  );
}

/// Warna aktif aplikasi.
///
/// Nilainya mengikuti palet yang sedang dipakai, jadi bukan `const` lagi.
/// Paletnya ditukar oleh [ThemeController], yang sekaligus memaksa seluruh
/// widget membangun ulang supaya tidak ada yang tertinggal dengan warna lama.
class AppColor {
  AppColor._();

  static AppPalette _p = AppPalette.light;

  static AppPalette get palette => _p;
  static bool get isDark => identical(_p, AppPalette.dark);

  static void use(Brightness brightness) {
    _p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  }

  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryLight => _p.primaryLight;

  static Color get primarySurface => _p.primarySurface;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get border => _p.border;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textDisabled => _p.textDisabled;

  static Color get success => _p.success;
  static Color get successSurface => _p.successSurface;

  static Color get warning => _p.warning;
  static Color get warningSurface => _p.warningSurface;

  static Color get danger => _p.danger;
  static Color get dangerSurface => _p.dangerSurface;

  static Color get info => _p.info;
  static Color get infoSurface => _p.infoSurface;
}
