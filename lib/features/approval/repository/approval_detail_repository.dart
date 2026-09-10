import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/approval_detail_model.dart';

class ApprovalDetailRepository {
  Future<Either<String, ApprovalDetailResponseModel>> getDetail(
    String approvalId,
  ) async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/approvals/$approvalId/detail");

      logger.d("response data detail +> ${response.data}");
      logger.d("response code detail +> ${response.statusCode}");
      logger.d("Request URL detail: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(ApprovalDetailResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}