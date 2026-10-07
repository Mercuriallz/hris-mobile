import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';

import 'storage.dart';

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