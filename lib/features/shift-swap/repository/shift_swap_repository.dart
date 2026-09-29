import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/shift_swap_model.dart';

class ShiftSwapRepository {
  Future<Either<String, SwapCandidateResponseModel>> candidates(
    String employeeShiftId, {
    String? targetDate,
  }) async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get(
        "/me/shift-swap/candidates",
        queryParameters: {
          "employeeShiftId": employeeShiftId,
          "targetDate": ?targetDate,
        },
      );

      logger.d("response code swap candidates +> ${response.statusCode}");

      if (response.statusCode == 200) {
        return Right(SwapCandidateResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }

  Future<Either<String, SwapRequestResponseModel>> myRequests() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/shift-swap");

      logger.d("response code my swaps +> ${response.statusCode}");

      if (response.statusCode == 200) {
        return Right(SwapRequestResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}