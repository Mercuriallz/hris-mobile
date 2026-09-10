import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
///
/// Hasilnya selalu ditulis kembali ke secure storage supaya langkah 2 dan 3
/// cuma terjadi sekali.
class DeviceIdService {
  static const _key = 'deviceId';

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  DeviceIdService({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfo,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<String> get() async {
    final cached = await _storage.read(key: _key);
    if (cached != null && cached.isNotEmpty) return cached;

    final id = await _fromPlatform() ?? _random();
    await _storage.write(key: _key, value: id);
    return id;
  }

  Future<String?> _fromPlatform() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id.isNotEmpty ? 'android-${info.id}' : null;
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final vendorId = info.identifierForVendor;
        return (vendorId != null && vendorId.isNotEmpty)
            ? 'ios-$vendorId'
            : null;
      }
    } catch (_) {
   
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
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {
      return 'Perangkat tidak dikenal';
    }
    return 'Perangkat tidak dikenal';
  }
}