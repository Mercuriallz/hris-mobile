import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../helper/slip_unlock.dart';
import '../model/salary_slip_model.dart';

const _expiredMessage = 'Sesi PIN habis. Masukkan PIN lagi untuk melihat slip gaji.';

/// Server menolak karena token buka-kunci hilang atau kedaluwarsa: kunci lagi supaya PIN diminta ulang.
bool _expired(Response response) {
  if (response.statusCode == 403 && errorCodeFromResponse(response) == 'SlipPinRequired') {
    SlipUnlock.instance.expire();
    return true;
  }
  return false;
}

class SalarySlipRepository {
  Future<Either<String, List<SalarySlip>>> getMine() async {
    final dio = await DioService.getInstance();
    try {
      final response = await dio.get('/me/salary-slips', options: Options(headers: SlipUnlock.instance.headers));
      if (_expired(response)) return const Left(_expiredMessage);
      if (response.statusCode == 200) {
        final data = (response.data['data'] as List?) ?? const [];
        return Right(
          data.map((e) => SalarySlip.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
      return Left(errorMessageFromResponse(response));
    } catch (e) {
      return Left(errorMessage(e));
    }
  }

  Future<Either<String, SalarySlip>> getOne(String id) async {
    final dio = await DioService.getInstance();
    try {
      final response = await dio.get('/me/salary-slips/$id', options: Options(headers: SlipUnlock.instance.headers));
      if (_expired(response)) return const Left(_expiredMessage);
      if (response.statusCode == 200) {
        return Right(SalarySlip.fromJson(response.data['data'] as Map<String, dynamic>));
      }
      return Left(errorMessageFromResponse(response));
    } catch (e) {
      return Left(errorMessage(e));
    }
  }

  /// Mengunduh PDF ke folder sementara dan mengembalikan lokasinya.
  ///
  /// Folder sementara, bukan Dokumen: slip gaji itu data pribadi, dan berkas
  /// yang tertinggal di folder umum bisa terbaca aplikasi lain.
  Future<Either<String, String>> downloadPdf(SalarySlip slip) async {
    final dio = await DioService.getInstance();
    try {
      final response = await dio.get<List<int>>(
        '/me/salary-slips/${slip.id}/pdf',
        options: Options(responseType: ResponseType.bytes, headers: SlipUnlock.instance.headers),
      );
      if (response.statusCode == 403) {
        SlipUnlock.instance.expire();
        return const Left(_expiredMessage);
      }
      if (response.statusCode != 200 || response.data == null) {
        return const Left('Gagal mengunduh slip gaji. Coba lagi.');
      }
      final dir = await getTemporaryDirectory();
      final name = 'Slip_Gaji_${slip.month}'.replaceAll(RegExp(r'[^\w\-]+'), '_');
      final file = File(p.join(dir.path, '$name.pdf'));
      await file.writeAsBytes(response.data!, flush: true);
      return Right(file.path);
    } catch (e) {
      return Left(errorMessage(e));
    }
  }
}
