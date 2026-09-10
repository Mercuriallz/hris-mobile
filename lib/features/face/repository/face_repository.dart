import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/face_status_model.dart';

class FaceRepository {
  Future<Either<String, FaceStatusResponseModel>> status() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/face/status");

      logger.d("response code face status +> ${response.statusCode}");
      logger.d("Request URL face status: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(FaceStatusResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}