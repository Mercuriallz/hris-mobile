import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/overtime_model.dart';

class OvertimeRepository {
  Future<Either<String, OvertimeRequestResponseModel>> getMyRequests() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/overtime");

      logger.d("response code overtime +> ${response.statusCode}");
      logger.d("Request URL overtime: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(OvertimeRequestResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}