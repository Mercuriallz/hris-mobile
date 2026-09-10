import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class TokenStorage {
  static const _keyToken = 'accessToken';
  static const _keyUser = 'authUser';
  static const _keyRole = 'authRole';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> save({
    required String accessToken,
    required String role,
    required Map<String, dynamic> user,
  }) async {
    await _storage.write(key: _keyToken, value: accessToken);
    await _storage.write(key: _keyRole, value: role);
    await _storage.write(key: _keyUser, value: jsonEncode(user));
  }

  Future<String?> readToken() => _storage.read(key: _keyToken);

  Future<String?> readRole() => _storage.read(key: _keyRole);

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _keyUser);
    if (raw == null) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Data rusak lebih baik dianggap tidak ada daripada membuat aplikasi
      // gagal terbuka setiap kali dijalankan.
      return null;
    }
  }

  /// Menghapus sesi, TIDAK menghapus deviceId.
  ///
  /// deviceId harus bertahan melewati logout. Kalau ikut terhapus, karyawan
  /// yang logout lalu login lagi akan terlihat seperti memakai perangkat baru
  /// dan ditolak — sampai HR mereset perangkatnya.
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyUser);
  }
}