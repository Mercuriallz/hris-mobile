import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/attendance_history_model.dart';

class AttendanceHistoryRepository {
  Future<Either<String, AttendanceHistoryResponseModel>> getHistory(
    String from,
    String to,
  ) async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get(
        "/me/attendance/history",
        queryParameters: {"from": from, "to": to},
      );

      logger.d("response data history +> ${response.data}");
      logger.d("response code history +> ${response.statusCode}");
      logger.d("Request URL history: ${response.realUri}");

      if (response.statusCode == 200) {
        final historyModel =
            AttendanceHistoryResponseModel.fromJson(response.data);
        return Right(historyModel);
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}