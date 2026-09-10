import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/helper/dio_service.dart';
import 'package:hris_mobile/helper/error_message.dart';
import 'package:hris_mobile/helper/file_upload_service.dart';


import 'photo_state.dart';

class PhotoCubit extends Cubit<PhotoState> {
  PhotoCubit() : super(PhotoInitial());

  void upload(String path) async {
    try {
      emit(PhotoUploading('Mengunggah foto...'));

      final fileId = await FileUploadService().upload(path, 'employee_photo');

      emit(PhotoUploading('Menyimpan...'));

      final dio = await DioService.getInstance();
      final response = await dio.patch(
        "/me/photo",
        data: {"photoFileId": fileId},
      );

      debugPrint("ganti foto profil: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>?;
        emit(PhotoUploaded(data?['photoUrl'] as String?));
        return;
      }

      emit(PhotoError(errorMessageFromResponse(response)));
    } on FileUploadFailure catch (e) {
      emit(PhotoError(e.message));
    } catch (e) {
      emit(PhotoError(errorMessage(e)));
    }
  }

  void reset() => emit(PhotoInitial());
}