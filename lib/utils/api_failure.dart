import 'package:dio/dio.dart';


class ApiFailure {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiFailure({required this.message, this.code, this.statusCode});

  factory ApiFailure.fromDio(DioException e) {

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiFailure(
        message:
            'Tidak bisa menghubungi server. Periksa koneksi internet Anda.',
        code: 'NoConnection',
      );
    }

    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final rawMessage = data['message'];


      final message = rawMessage is List
          ? (rawMessage.isNotEmpty ? rawMessage.first.toString() : null)
          : rawMessage?.toString();

      return ApiFailure(
        message: message ?? 'Terjadi kesalahan pada server.',
        code: data['error']?.toString(),
        statusCode: e.response?.statusCode,
      );
    }

    return ApiFailure(
      message: 'Terjadi kesalahan pada server.',
      statusCode: e.response?.statusCode,
    );
  }

  factory ApiFailure.local(String message, {String? code}) =>
      ApiFailure(message: message, code: code);

  @override
  String toString() => 'ApiFailure($statusCode, $code): $message';
}