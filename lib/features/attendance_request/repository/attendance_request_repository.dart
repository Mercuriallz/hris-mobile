import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/attendance_request_model.dart';

/// Hanya GET. Pengiriman pengajuan ada di cubit.
class AttendanceRequestRepository {
  Future<Either<String, AttendanceRequestResponseModel>> getMyRequests() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/attendance-requests");

      logger.d("response data requests +> ${response.data}");
      logger.d("response code requests +> ${response.statusCode}");
      logger.d("Request URL requests: ${response.realUri}");

      if (response.statusCode == 200) {
        final model = AttendanceRequestResponseModel.fromJson(response.data);
        return Right(model);
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}