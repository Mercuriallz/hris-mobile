import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/shift_card_model.dart';

/// Hanya GET. Clock in dan clock out ada di cubit.
class AttendanceRepository {
  /// Kartu shift kemarin sampai besok.
  ///
  /// Rentangnya tiga hari, bukan hari ini saja, karena shift malam berjangkar
  /// pada tanggal mulainya: orang yang shift 22:00 kemarin masih perlu clock
  /// out pagi ini, dan kartunya bertanggal kemarin.
  Future<Either<String, ShiftCardResponseModel>> myShifts() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/attendance/shifts");

      logger.d("response data shifts +> ${response.data}");
      logger.d("response code shifts +> ${response.statusCode}");
      logger.d("Request URL shifts: ${response.realUri}");

      if (response.statusCode == 200) {
        final shiftModel = ShiftCardResponseModel.fromJson(response.data);
        return Right(shiftModel);
      } else {
        // Pesan dari backend dipakai apa adanya, bukan diganti "Terjadi
        // kesalahan". Selubung responsnya sudah berisi kalimat yang ditulis
        // untuk dibaca karyawan — mengganti dengan pesan generik justru
        // membuang satu-satunya keterangan yang berguna.
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}