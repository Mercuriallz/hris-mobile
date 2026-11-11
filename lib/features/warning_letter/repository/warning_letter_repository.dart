import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/warning_letter_model.dart';

class WarningLetterRepository {
  Future<Either<String, List<WarningLetter>>> getMine() async {
    final dio = await DioService.getInstance();
    try {
      final response = await dio.get('/me/warning-letters');
      if (response.statusCode == 200) {
        final data = (response.data['data'] as List?) ?? const [];
        return Right(
          data.map((e) => WarningLetter.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
      return Left(errorMessageFromResponse(response));
    } catch (e) {
      return Left(errorMessage(e));
    }
  }

  /// Membuka detail sekaligus mencatat di server bahwa surat sudah dibaca.
  Future<Either<String, WarningLetter>> getOne(String id) async {
    final dio = await DioService.getInstance();
    try {
      final response = await dio.get('/me/warning-letters/$id');
      if (response.statusCode == 200) {
        return Right(WarningLetter.fromJson(response.data['data'] as Map<String, dynamic>));
      }
      return Left(errorMessageFromResponse(response));
    } catch (e) {
      return Left(errorMessage(e));
    }
  }

  /// Mengunduh PDF ke folder sementara dan mengembalikan lokasinya.
  ///
  /// Folder sementara, bukan Dokumen: surat peringatan itu data pribadi, dan
  /// berkas yang tertinggal di folder umum bisa terbaca aplikasi lain.
  Future<Either<String, String>> downloadPdf(WarningLetter letter) async {
    final dio = await DioService.getInstance();
    try {
      final response = await dio.get<List<int>>(
        '/me/warning-letters/${letter.id}/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200 || response.data == null) {
        return const Left('Gagal mengunduh surat. Coba lagi.');
      }
      final dir = await getTemporaryDirectory();
      final name = '${letter.levelLabel}_${letter.issuedDate}'.replaceAll(RegExp(r'[^\w\-]+'), '_');
      final file = File(p.join(dir.path, '$name.pdf'));
      await file.writeAsBytes(response.data!, flush: true);
      return Right(file.path);
    } catch (e) {
      return Left(errorMessage(e));
    }
  }
}
