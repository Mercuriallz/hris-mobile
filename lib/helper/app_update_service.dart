import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../constant/theme/app_color.dart';

/// Pengingat pembaruan aplikasi lewat In-App Updates API milik Google Play.
///
/// Dua jalur, dipilih dari prioritas rilis yang diset di Play Console:
///
///   Prioritas >= [_immediatePriority] → pembaruan IMMEDIATE. Layar penuh
///   dari Play, aplikasi tidak bisa dipakai sampai pembaruannya terpasang.
///   Untuk rilis yang memperbaiki bug kritis atau mengikuti perubahan API.
///
///   Selain itu → pembaruan FLEXIBLE. Play menawarkan pembaruan, unduhannya
///   berjalan di belakang selagi karyawan tetap bisa absen, lalu muncul
///   snackbar untuk memulai ulang begitu unduhan selesai.
///
/// Prioritas tidak bisa diset dari halaman web Play Console, hanya lewat
/// Publishing API (`inAppUpdatePriority`). Rilis tanpa prioritas bernilai 0
/// dan selalu jatuh ke jalur flexible.
///
/// Hanya berjalan di Android dan hanya untuk aplikasi yang dipasang dari
/// Play Store. Build debug atau APK yang di-sideload akan gagal di
/// [InAppUpdate.checkForUpdate]; kegagalan itu sengaja ditelan.
class AppUpdateService {
  static const _immediatePriority = 4;

  /// Dipasang ke `MaterialApp.scaffoldMessengerKey` supaya snackbar
  /// "mulai ulang" bisa tampil di halaman mana pun yang sedang terbuka.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool _checking = false;
  static StreamSubscription<InstallStatus>? _installSub;
  static _ResumeObserver? _observer;

  /// Dipanggil sekali setelah splash selesai mengarahkan pengguna.
  static Future<void> check() async {
    if (!Platform.isAndroid || _checking) return;
    _checking = true;

    try {
      _observer ??= _ResumeObserver()..attach();

      final info = await InAppUpdate.checkForUpdate();

      // Unduhan flexible dari sesi sebelumnya sudah selesai tapi belum
      // dipasang. Tanpa ini, pembaruannya menggantung sampai Play memasangnya
      // sendiri saat aplikasi tidak dipakai.
      if (info.installStatus == InstallStatus.downloaded) {
        _showRestartPrompt();
        return;
      }

      // Pembaruan immediate yang terputus (aplikasi ditutup di tengah jalan)
      // harus dilanjutkan, kalau tidak pengguna lolos dari pembaruan wajib.
      if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (info.updatePriority >= _immediatePriority &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await _startFlexible();
      }
    } catch (e) {
      debugPrint('Cek pembaruan aplikasi gagal: $e');
    } finally {
      _checking = false;
    }
  }

  static Future<void> _startFlexible() async {
    _installSub ??= InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) _showRestartPrompt();
    });

    final result = await InAppUpdate.startFlexibleUpdate();
    if (result != AppUpdateResult.success) {
      await _installSub?.cancel();
      _installSub = null;
    }
  }

  /// Saat aplikasi kembali ke depan, cek apakah unduhan flexible selesai
  /// selagi aplikasi di latar belakang. Listener bisa saja melewatkannya.
  static Future<void> _onResume() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded) _showRestartPrompt();
    } catch (_) {}
  }

  static void _showRestartPrompt() {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Versi terbaru aplikasi sudah siap dipasang.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
          backgroundColor: AppColor.textPrimary,
          action: SnackBarAction(
            label: 'MULAI ULANG',
            textColor: AppColor.primaryLight,
            onPressed: () {
              unawaited(InAppUpdate.completeFlexibleUpdate().catchError((_) {}));
            },
          ),
        ),
      );
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  void attach() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AppUpdateService._onResume());
    }
  }
}
