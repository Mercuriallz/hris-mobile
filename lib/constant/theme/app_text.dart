import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';

/// Skala tipografi aplikasi.
///
/// Tujuh ukuran, dan itu batasnya. Setiap ukuran tambahan mengurangi
/// kejelasan hierarki — kalau ada dua ukuran yang selisihnya dua piksel, mata
/// tidak bisa membedakannya sebagai tingkat yang berbeda, jadi keduanya cuma
/// menambah pilihan tanpa menambah arti.
class AppText {
  AppText._();

  /// Angka besar untuk jam dan hitungan. Tabular figures supaya digitnya
  /// tidak bergeser tiap menit berubah — jam yang melompat-lompat terlihat
  /// seperti kerusakan.
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: AppColor.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColor.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColor.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColor.textPrimary,
      );

  static TextStyle get bodyStrong => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: AppColor.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColor.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.4,
        color: AppColor.textSecondary,
      );
}