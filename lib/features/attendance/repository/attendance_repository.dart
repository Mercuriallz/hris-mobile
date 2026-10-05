import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/shift_card_model.dart';

class AttendanceRepository {

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
     
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}