import 'package:dio/dio.dart';

/// Menerjemahkan kegagalan jadi pesan yang bisa dibaca orang.
///
/// Backend selalu membalas dalam selubung `{statusCode, message, error}`, dan
/// pesan di dalamnya sudah ditulis untuk dibaca pengguna — bukan kode teknis.
/// Jadi tugas fungsi ini cuma mengeluarkannya.
///
/// `e.toString()` sebagai pesan terakhir sengaja dihindari: "DioException
/// [bad response]: ..." tidak memberi tahu karyawan apa yang harus dia
/// lakukan, dan itu satu-satunya hal yang berguna saat sesuatu gagal.
String errorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Tidak bisa menghubungi server. Periksa koneksi internet Anda.';
    }

    final data = error.response?.data;
    if (data is Map) {
      final raw = data['message'];

      // ValidationPipe mengembalikan message sebagai array. Diambil yang
      // pertama saja — menampilkan sepuluh baris sekaligus tidak membantu.
      if (raw is List && raw.isNotEmpty) return raw.first.toString();
      if (raw != null) return raw.toString();
    }

    return 'Terjadi kesalahan pada server.';
  }

  if (error is LocationFailure) return error.message;

  return 'Terjadi kesalahan. Coba lagi.';
}


String? errorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) return data['error']?.toString();
  }
  if (error is LocationFailure) return error.code;
  return null;
}

String errorMessageFromResponse(Response response) {
  final data = response.data;

  if (data is Map) {
    final raw = data['message'];
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    if (raw != null) return raw.toString();
  }

  return 'Terjadi kesalahan pada server.';
}

String? errorCodeFromResponse(Response response) {
  final data = response.data;
  if (data is Map) return data['error']?.toString();
  return null;
}

/// Kegagalan yang berasal dari perangkat, bukan dari server.
class LocationFailure implements Exception {
  final String message;
  final String? code;

  const LocationFailure(this.message, {this.code});

  @override
  String toString() => message;
}