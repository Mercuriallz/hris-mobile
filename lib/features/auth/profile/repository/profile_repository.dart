import 'package:fpdart/fpdart.dart';
import 'package:hris_mobile/helper/dio_service.dart';
import 'package:hris_mobile/helper/error_message.dart';
import 'package:logger/logger.dart';


import '../model/my_profile_model.dart';

class ProfileRepository {
  Future<Either<String, MyProfileResponseModel>> getMyProfile() async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final response = await dio.get("/me");

      logger.d("response code me +> ${response.statusCode}");
      logger.d("Request URL me: ${response.realUri}");

      if (response.statusCode == 200) {
        return Right(MyProfileResponseModel.fromJson(response.data));
      } else {
        return Left(errorMessageFromResponse(response));
      }
    } catch (e) {
      return left(errorMessage(e));
    }
  }
}