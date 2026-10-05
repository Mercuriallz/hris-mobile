import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/approval_model.dart';

class ApprovalRepository {

  Future<Either<String, ApprovalResponseModel>> getInbox() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/approvals/inbox");

      logger.d("response data inbox +> ${response.data}");
      logger.d("response code inbox +> ${response.statusCode}");
      logger.d("Request URL inbox: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(ApprovalResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}