import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../constant/route/app_route.dart';
import 'storage.dart';

/// Mengarahkan ketukan notifikasi ke layar yang dimaksud.
///
/// Masalahnya bukan navigasinya — itu satu baris. Masalahnya KAPAN
/// ketukan itu datang, dan ada tiga keadaan yang perlakuannya berbeda:
///
///   Aplikasi terbuka. Router siap, orangnya sudah login. Langsung pindah.
///
///   Aplikasi di latar belakang. Sama saja — router masih hidup.
///
///   Aplikasi tertutup penuh. Ini yang menyulitkan. Ketukan membangunkan
///   aplikasi dari nol, dan event-nya sampai SEBELUM splash selesai
///   memeriksa sesi. Kalau langsung dinavigasi, orangnya mendarat di
///   halaman detail tanpa token dan dapat 401 — atau lebih buruk, layar
///   kosong tanpa penjelasan.
///
/// Jalan keluarnya: tujuan disimpan dulu, dibuka setelah ada yang
/// memastikan orangnya memang sudah masuk.
class PushRouting {
  PushRouting._();

  /// Tujuan yang menunggu dibuka.
  ///
  /// Diisi saat ketukan datang tapi belum bisa dilayani, dan dikosongkan
  /// begitu dibuka. Disimpan di memori, bukan di penyimpanan — tujuan yang
  /// bertahan melewati penutupan aplikasi akan membuka layar acak di
  /// pembukaan berikutnya, dan orangnya tidak akan tahu kenapa.
  static String? _pending;

  /// Dipasang sekali di main, setelah PushService.initialize().
  static void attach() {
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data == null) return;

      final type = data['type'];
      final approvalId = data['approvalId'];

      if (type != 'approval' || approvalId is! String || approvalId.isEmpty) {
        debugPrint('Ketukan notifikasi tanpa tujuan yang dikenali: $data');
        return;
      }

            _pending = approvalId;
      unawaited(consumeIfReady());
    });
  }

  /// Membuka tujuan yang menunggu, kalau ada dan kalau sudah boleh.
  ///
  /// Dipanggil tiga kali dari tempat berbeda: saat ketukan datang, setelah
  /// splash memutuskan arah, dan setelah login berhasil. Aman dipanggil
  /// berkali-kali — yang tidak punya tujuan langsung keluar.
  static Future<void> consumeIfReady() async {
    final id = _pending;
    if (id == null) return;

    // Token dibaca dari penyimpanan, bukan dari state aplikasi. Saat
    // dingin, cubit mana pun belum tentu sudah hidup.
    final token = await SecureStorageService().read('token');
    if (token == null || token.isEmpty) {
      // Biarkan menunggu. Login yang berhasil akan memanggil ini lagi.
      return;
    }

    _pending = null;

    // push, bukan go — supaya tombol kembali membawa ke layar sebelumnya,
    // bukan menutup aplikasi.
    router.push('/approval/$id');
  }

  /// Dibuang saat keluar.
  ///
  /// Tanpa ini, tujuan yang menunggu dari akun sebelumnya akan dibuka oleh
  /// orang yang login berikutnya di perangkat yang sama — dan dia akan
  /// melihat pengajuan yang bukan urusannya, atau 403.
  static void clear() {
    _pending = null;
  }
}