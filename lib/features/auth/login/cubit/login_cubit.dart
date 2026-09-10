import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/helper/device_helper.dart';
import 'package:hris_mobile/helper/dio_service.dart';
import 'package:hris_mobile/helper/error_message.dart';
import 'package:hris_mobile/helper/storage.dart';


import '../cubit/login_state.dart';
import '../model/login_request_model.dart';
import '../model/login_response_model.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  void login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(LoginError("Email dan password harus diisi."));
      return;
    }

    final secureStorage = SecureStorageService();
    final dio = await DioService.getInstance();
    final deviceIdService = DeviceIdService();

    emit(LoginLoading());

    try {
      final formData = LoginRequestModel(
        email: email,
        password: password,
        deviceId: await deviceIdService.get(),
        deviceModel: await deviceIdService.describe(),
      );

      final response = await dio.post(
        "/auth/signin",
        data: formData.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginModel = LoginResponseModel.fromJson(response.data);
        final data = loginModel.data;

        if (data == null || data.accessToken == null || data.user == null) {
          emit(LoginError("Balasan server tidak lengkap. Coba lagi."));
          return;
        }

        // Owner dan Super Admin tidak punya data kepegawaian, jadi tidak punya
        // shift untuk diabsen. Ditolak di sini dengan pesan yang mengarahkan,
        // bukan dibiarkan masuk lalu menemukan layar kosong.
        if (data.user!.employeeId == null) {
          emit(LoginError(
            "Akun ini tidak terhubung ke data kepegawaian, jadi tidak bisa absen. "
            "Kalau Anda pengelola, gunakan dashboard web.",
          ));
          return;
        }

        await secureStorage.write("token", data.accessToken!);
        await secureStorage.write("role", data.role ?? "employee");
        await secureStorage.write("fullname", data.user!.name ?? "");
        await secureStorage.write("email", data.user!.email ?? "");
        await secureStorage.write("employeeId", data.user!.employeeId!);
        await secureStorage.write("groupId", data.user!.groupId ?? "");

        debugPrint("Login sebagai ${data.user!.name} (${data.role})");

        if (data.user!.mustChangePassword == true) {
          emit(LoginMustChangePassword("Password harus diganti"));
          return;
        }

        emit(LoginSuccess("Selamat datang, ${data.user!.name}"));
      } else {
        emit(LoginError(
          errorMessageFromResponse(response),
        ));
      }
    } catch (e) {
      emit(LoginError(errorMessage(e)));
    }
  }

  void changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword.length < 8) {
      emit(LoginError("Password baru minimal 8 karakter."));
      return;
    }
    if (newPassword != confirmPassword) {
      emit(LoginError("Konfirmasi password tidak sama."));
      return;
    }

    final dio = await DioService.getInstance();

    emit(LoginLoading());

    try {
      final formData = ChangePasswordRequestModel(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final response = await dio.patch(
        "/auth/change-password",
        data: formData.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(LoginSuccess("Password berhasil diganti"));
      } else {
        emit(LoginError(
          errorMessageFromResponse(response),
        ));
      }
    } catch (e) {
      emit(LoginError(errorMessage(e)));
    }
  }

  /// Dipakai splash untuk memutuskan arah pertama. Bukan panggilan jaringan —
  /// cuma membaca secure storage.
  Future<bool> hasSession() async {
    final token = await SecureStorageService().read("token");
    return token != null && token.isNotEmpty;
  }

  void logout() async {
    await SecureStorageService().clearSession();
    emit(LoginInitial());
  }
}