import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'device_helper.dart';
import 'dio_service.dart';

/// Notifikasi push lewat OneSignal.
///
/// Dua tanggung jawab yang sengaja dipisah:
///
///   [initialize] dipanggil sekali di main, sebelum aplikasi tampil. Dia cuma
///   menyalakan SDK; belum ada token, belum ada izin.
///
///   [registerToken] dipanggil SETELAH login berhasil. Baru di situ aplikasi
///   tahu karyawan mana yang memegang perangkat ini, dan baru di situ ada
///   token akses untuk memanggil backend.
///
/// Urutan itu penting. Mendaftarkan token sebelum login berarti tidak ada
/// karyawan yang bisa dipasangi, dan permintaannya akan ditolak 401.
class PushService {
  static const _timeout = Duration(seconds: 10);

  /// Menyalakan SDK OneSignal.
  ///
  /// Tidak meminta izin di sini. Permintaan izin yang muncul di detik pertama
  /// aplikasi dibuka — sebelum orangnya tahu aplikasi ini untuk apa — hampir
  /// selalu ditolak, dan di Android penolakan itu tidak bisa ditanyakan lagi
  /// tanpa masuk ke pengaturan sistem.
  static Future<void> initialize() async {
    final appId = dotenv.env['ONESIGNAL_APP_ID'];

    if (appId == null || appId.isEmpty) {
      debugPrint('ONESIGNAL_APP_ID kosong — notifikasi push dimatikan');
      return;
    }

    OneSignal.Debug.setLogLevel(kDebugMode ? OSLogLevel.warn : OSLogLevel.none);
    OneSignal.initialize(appId);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });
  }

  /// Meminta izin lalu mengirim token ke backend.
  ///
  /// Dipanggil setiap kali login berhasil, bukan sekali saat pertama pasang.
  /// OneSignal mengganti token sendiri pada beberapa keadaan — pasang ulang
  /// aplikasi, bersihkan data, kadang pembaruan sistem — dan token lama
  /// berhenti bekerja tanpa pemberitahuan apa pun ke server. Perangkat yang
  /// diam karena tokennya basi tidak bisa dibedakan dari perangkat yang
  /// memang tidak dipakai.
  ///
  /// SELURUH KEGAGALAN DITELAN. Notifikasi yang tidak jalan itu
  /// ketidaknyamanan; login yang gagal karena pendaftaran notifikasinya gagal
  /// itu kerusakan.
  static Future<void> registerToken() async {
    try {
      final appId = dotenv.env['ONESIGNAL_APP_ID'];
      if (appId == null || appId.isEmpty) return;

      // Izin diminta di sini, setelah orangnya login dan sudah tahu aplikasi
      // ini untuk apa. Yang menolak tetap bisa memakai seluruh fitur lain.
      final granted = await OneSignal.Notifications.requestPermission(true);
      if (!granted) {
        debugPrint('Izin notifikasi ditolak — token tidak didaftarkan');
        return;
      }

      final token = await _waitForSubscriptionId();
      if (token == null) {
        debugPrint('Token OneSignal belum siap setelah $_timeout');
        return;
      }

      // deviceId yang SAMA dengan yang dipakai login.
      //
      // Backend mencocokkan token ke baris perangkat lewat pasangan
      // employeeId + deviceId. Kalau nilainya berbeda sedikit saja, tidak ada
      // baris yang cocok, dan tokennya terbuang tanpa ada yang tahu —
      // backend cuma mencatat peringatan.
      final deviceId = await DeviceIdService().get();

      final dio = await DioService.getInstance();
      await dio.patch(
        '/me/push-token',
        data: {'deviceId': deviceId, 'pushToken': token},
      );

      debugPrint('Token notifikasi terdaftar untuk perangkat $deviceId');
    } catch (e) {
      debugPrint('Pendaftaran token notifikasi gagal: $e');
    }
  }

  /// Menunggu OneSignal menyiapkan id langganannya.
  ///
  /// Id-nya tidak langsung ada setelah izin diberikan — SDK masih perlu
  /// mendaftar ke FCM dan menerima balasannya, dan itu melewati jaringan.
  /// Di koneksi seluler yang lambat bisa beberapa detik.
  ///
  /// Dibaca berulang alih-alih memasang listener karena pemanggilnya
  /// menunggu hasilnya; listener akan memaksa seluruh alur login jadi
  /// berbasis callback untuk satu nilai yang cuma dibaca sekali.
  static Future<String?> _waitForSubscriptionId() async {
    final deadline = DateTime.now().add(_timeout);

    while (DateTime.now().isBefore(deadline)) {
      final id = OneSignal.User.pushSubscription.id;
      if (id != null && id.isNotEmpty) return id;
      await Future.delayed(const Duration(milliseconds: 400));
    }

    return null;
  }

  /// Melepas langganan saat keluar.
  ///
  /// Perangkat yang dipakai bergantian — HP bersama di pos satpam, misalnya —
  /// tidak boleh mengirimkan notifikasi orang sebelumnya ke orang yang
  /// sekarang memegangnya. Tokennya di backend tetap tersimpan sampai
  /// perangkatnya dicabut HR; yang dimatikan di sini pengirimannya.
  static Future<void> unregister() async {
    try {
      OneSignal.User.pushSubscription.optOut();
    } catch (e) {
      debugPrint('Gagal melepas langganan notifikasi: $e');
    }
  }
}
