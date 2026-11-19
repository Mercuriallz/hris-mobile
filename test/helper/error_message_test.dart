import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/helper/error_message.dart';
import 'package:hris_mobile/utils/api_failure.dart';

const _noConn = 'Tidak bisa menghubungi server. Periksa koneksi internet Anda.';
final _ro = RequestOptions(path: '/x');

DioException dioErr(DioExceptionType type, {Object? data, int? status}) => DioException(
      requestOptions: _ro,
      type: type,
      response: status == null && data == null
          ? null
          : Response(requestOptions: _ro, statusCode: status ?? 500, data: data),
    );

void main() {
  group('errorMessage', () {
    for (final t in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$t → pesan koneksi', () => expect(errorMessage(dioErr(t)), _noConn));
    }

    test('message string dari server', () {
      expect(
        errorMessage(dioErr(DioExceptionType.badResponse, data: {'message': 'Slip tidak ditemukan', 'error': 'NotFound'})),
        'Slip tidak ditemukan',
      );
    });

    test('message array (ValidationPipe) → elemen pertama', () {
      expect(
        errorMessage(dioErr(DioExceptionType.badResponse, data: {
          'message': ['reason wajib diisi', 'tanggal tidak valid']
        })),
        'reason wajib diisi',
      );
    });

    test('tanpa body / body bukan Map → pesan umum server', () {
      expect(errorMessage(dioErr(DioExceptionType.badResponse, status: 502)), 'Terjadi kesalahan pada server.');
      expect(errorMessage(dioErr(DioExceptionType.badResponse, data: '<html>')), 'Terjadi kesalahan pada server.');
      expect(errorMessage(dioErr(DioExceptionType.badResponse, data: [1, 2])), 'Terjadi kesalahan pada server.');
    });

    test('LocationFailure & error lain', () {
      expect(errorMessage(const LocationFailure('GPS mati', code: 'GPS_OFF')), 'GPS mati');
      expect(errorMessage(Exception('x')), 'Terjadi kesalahan. Coba lagi.');
      expect(errorMessage(TypeError()), 'Terjadi kesalahan. Coba lagi.');
    });

    test('message array kosong → pesan umum, bukan "[]"', () {
      expect(errorMessage(dioErr(DioExceptionType.badResponse, data: {'message': []})), 'Terjadi kesalahan pada server.');
    });

    test('sendTimeout (unggah foto/berkas lambat) → pesan koneksi', () {
      expect(errorMessage(dioErr(DioExceptionType.sendTimeout)), _noConn);
    });
  });

  group('errorCode / errorMessageFromResponse / errorCodeFromResponse', () {
    test('kode dari server', () {
      expect(errorCode(dioErr(DioExceptionType.badResponse, data: {'error': 'OUT_OF_RADIUS'})), 'OUT_OF_RADIUS');
      expect(errorCode(const LocationFailure('x', code: 'MOCKED')), 'MOCKED');
      expect(errorCode(Exception()), isNull);
    });

    test('dari Response 4xx (validateStatus < 500)', () {
      final r = Response(requestOptions: _ro, statusCode: 400, data: {
        'message': ['a', 'b'],
        'error': 'BadRequest'
      });
      expect(errorMessageFromResponse(r), 'a');
      expect(errorCodeFromResponse(r), 'BadRequest');
      final r2 = Response(requestOptions: _ro, statusCode: 404, data: null);
      expect(errorMessageFromResponse(r2), 'Terjadi kesalahan pada server.');
      expect(errorCodeFromResponse(r2), isNull);
    });
  });

  group('ApiFailure.fromDio', () {
    test('koneksi', () {
      final f = ApiFailure.fromDio(dioErr(DioExceptionType.connectionError));
      expect(f.message, _noConn);
      expect(f.code, 'NoConnection');
      expect(f.statusCode, isNull);
    });

    test('respons Map dengan message array / kosong / string', () {
      var f = ApiFailure.fromDio(dioErr(DioExceptionType.badResponse,
          status: 400, data: <String, dynamic>{'message': ['x', 'y'], 'error': 'BadRequest'}));
      expect(f.message, 'x');
      expect(f.code, 'BadRequest');
      expect(f.statusCode, 400);
      f = ApiFailure.fromDio(dioErr(DioExceptionType.badResponse, status: 400, data: <String, dynamic>{'message': []}));
      expect(f.message, 'Terjadi kesalahan pada server.');
      f = ApiFailure.fromDio(dioErr(DioExceptionType.badResponse, status: 409, data: <String, dynamic>{'message': 'Bentrok'}));
      expect(f.message, 'Bentrok');
      expect(f.toString(), 'ApiFailure(409, null): Bentrok');
    });

    test('respons bukan Map', () {
      final f = ApiFailure.fromDio(dioErr(DioExceptionType.badResponse, status: 503, data: 'down'));
      expect(f.message, 'Terjadi kesalahan pada server.');
      expect(f.statusCode, 503);
    });

    test('local', () {
      final f = ApiFailure.local('Kamera ditolak', code: 'CAMERA');
      expect(f.message, 'Kamera ditolak');
      expect(f.code, 'CAMERA');
    });
  });
}
