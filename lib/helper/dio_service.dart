import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'storage.dart';

/// Satu Dio untuk seluruh aplikasi.
///
/// Token disisipkan lewat interceptor, bukan diteruskan sebagai parameter ke
/// setiap panggilan. Dengan begitu tidak ada satu pun tempat yang bisa lupa
/// mengirimkannya, dan penanganan token kedaluwarsa cukup ditulis sekali.
class DioService {
  static Dio? _dio;

  /// Dipanggil saat server menolak token. Diisi di main.dart supaya lapisan
  /// jaringan tidak perlu tahu apa pun tentang rute.
  static void Function()? onUnauthorized;

  static Future<Dio> getInstance() async {
    if (_dio != null) return _dio!;

    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3001',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,

        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final storage = SecureStorageService();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read("token");
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) async {
          final status = response.statusCode ?? 0;

          if (status == 401) {
            await storage.clearSession();
            onUnauthorized?.call();
          }

          handler.next(response);
        },
        onError: (e, handler) {
          debugPrint('${e.requestOptions.path} gagal: ${e.message}');
          handler.next(e);
        },
      ),
    );

    _dio = dio;
    return dio;
  }
}