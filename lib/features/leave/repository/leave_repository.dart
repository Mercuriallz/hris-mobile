import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/leave_model.dart';

class LeaveRepository {
  Future<Either<String, LeaveBalanceResponseModel>> getBalance() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/leave/balance");

      logger.d("response data balance +> ${response.data}");
      logger.d("response code balance +> ${response.statusCode}");
      logger.d("Request URL balance: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(LeaveBalanceResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }

  Future<Either<String, LeaveTypeResponseModel>> getTypes() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/leave/types");

      logger.d("response code types +> ${response.statusCode}");
      logger.d("Request URL types: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(LeaveTypeResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }

  Future<Either<String, LeaveRequestResponseModel>> getMyRequests() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me/leave/requests");

      logger.d("response code leave requests +> ${response.statusCode}");
      logger.d("Request URL leave requests: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(LeaveRequestResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}