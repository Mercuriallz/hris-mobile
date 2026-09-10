import 'package:geolocator/geolocator.dart';

import 'error_message.dart';

/// Hasil pembacaan lokasi, sudah termasuk penanda GPS palsu.
class LocationReading {
  final double latitude;
  final double longitude;
  final int accuracy;

  /// Android melaporkan ini lewat Position.isMocked. iOS SELALU false — tidak
  /// ada API yang setara di sana. Jadi penanda ini hanya berarti untuk
  /// separuh pengguna, dan HR perlu tahu itu supaya tidak menyimpulkan bahwa
  /// pengguna iPhone lebih jujur.
  final bool isMocked;

  const LocationReading({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMocked,
  });
}

class LocationService {
  /// Akurasi terburuk yang masih diterima, dalam meter.
  ///
  /// Di dalam gedung, GPS sering melaporkan akurasi 100 meter atau lebih —
  /// dan pada radius kantor 150 meter, itu berarti titiknya bisa jatuh di
  /// mana saja. Lebih baik menyuruh orang menunggu sebentar daripada mencatat
  /// absensi di lokasi yang salah.
  ///
  /// Angka ini yang paling mungkin perlu disetel setelah tes lapangan.
  static const maxAcceptableAccuracy = 75;

  /// Melempar [LocationFailure] dengan pesan yang mengatakan apa yang harus
  /// dilakukan pengguna — bukan apa yang salah secara teknis. "Izin lokasi
  /// ditolak" tidak memberi tahu orang bahwa dia perlu membuka pengaturan.
  Future<LocationReading> read() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        'GPS di perangkat Anda mati. Nyalakan dulu lewat pengaturan, lalu coba lagi.',
        code: 'LocationServiceDisabled',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Aplikasi butuh izin lokasi untuk mencatat absensi. Ketuk Izinkan saat diminta.',
        code: 'LocationPermissionDenied',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      // Ditolak permanen tidak bisa diminta ulang dari dalam aplikasi —
      // satu-satunya jalan lewat pengaturan sistem, dan pesannya harus
      // mengatakan itu.
      throw const LocationFailure(
        'Izin lokasi diblokir permanen. Buka Pengaturan HP, cari aplikasi ini, lalu izinkan Lokasi.',
        code: 'LocationPermissionBlocked',
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const LocationFailure(
        'Lokasi belum bisa dibaca. Coba keluar ke area terbuka lalu ulangi.',
        code: 'LocationTimeout',
      );
    }

    final accuracy = position.accuracy.round();

    if (accuracy > maxAcceptableAccuracy) {
      throw LocationFailure(
        'Sinyal GPS masih lemah, akurasinya sekitar $accuracy meter. '
        'Tunggu beberapa detik atau keluar ke area terbuka, lalu coba lagi.',
        code: 'LowAccuracy',
      );
    }

    return LocationReading(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: accuracy,
      isMocked: position.isMocked,
    );
  }
}