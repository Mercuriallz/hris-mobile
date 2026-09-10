import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/summary_model.dart';

class SummaryRepository {
  Future<Either<String, SummaryResponseModel>> getSummary() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/summary");

      logger.d("response code summary +> ${response.statusCode}");
      logger.d("Request URL summary: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(SummaryResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}