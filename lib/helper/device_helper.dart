import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';

import 'storage.dart';

/// Identitas perangkat untuk pengikatan absensi.
///
/// Backend hanya mengizinkan satu perangkat per karyawan. Kalau id ini
/// berubah, orangnya ditolak saat login dan harus minta HR mereset
/// perangkatnya. Untuk dua ratus karyawan, id yang hilang setiap kali
/// aplikasi dipasang ulang berarti keluhan mingguan — jadi ketahanannya
/// adalah pertimbangan utama, bukan detail.
///
/// Urutannya:
///
///   1. Baca dari secure storage. Di iOS, Keychain bertahan melewati
///      penghapusan aplikasi, jadi ini saja sudah cukup di sana.
///
///   2. Kalau kosong, pakai identitas dari sistem operasi. Android ID
///      bertahan melewati pemasangan ulang dan hanya berubah saat reset
///      pabrik. identifierForVendor di iOS bertahan selama masih ada aplikasi
///      dari penerbit yang sama.
///
///   3. Kalau keduanya gagal, buat acak. Ini jalan terakhir — id acak tidak
///      bertahan melewati pemasangan ulang di Android, dan orangnya akan
///      perlu reset perangkat.
class DeviceIdService {
  static const _key = "deviceId";

  Future<String> get() async {
    final storage = SecureStorageService();

    final cached = await storage.read(_key);
    if (cached != null && cached.isNotEmpty) return cached;

    final id = await _fromPlatform() ?? _random();
    await storage.write(_key, id);
    return id;
  }

  Future<String?> _fromPlatform() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id.isNotEmpty ? 'android-${info.id}' : null;
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        final vendorId = info.identifierForVendor;
        return (vendorId != null && vendorId.isNotEmpty)
            ? 'ios-$vendorId'
            : null;
      }
    } catch (_) {
      // Beberapa ROM Android menyembunyikan atau mengubah nilai ini. Jatuh ke
      // acak daripada gagal sama sekali.
      return null;
    }
    return null;
  }

  String _random() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'gen-$hex';
  }

  /// Nama perangkat untuk ditampilkan HR di daftar perangkat.
  Future<String> describe() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {
      return 'Perangkat tidak dikenal';
    }
    return 'Perangkat tidak dikenal';
  }
}