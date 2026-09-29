import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/overtime/model/overtime_model.dart';
import 'package:hris_mobile/helper/dio_service.dart';
import 'package:hris_mobile/helper/error_message.dart';
import 'package:hris_mobile/helper/file_upload_service.dart';


import 'overtime_form_state.dart';

class OvertimeFormCubit extends Cubit<OvertimeFormState> {
  OvertimeFormCubit() : super(OvertimeFormInitial());


  void preview({
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    emit(OvertimeFormPreviewing());

    try {
      final dio = await DioService.getInstance();

      final response = await dio.post(
        "/me/overtime/preview",
        data: {
          "startAt": startAt.toUtc().toIso8601String(),
          "endAt": endAt.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            OvertimePreviewResponseModel.fromJson(response.data).data;

        if (data == null) {
          emit(OvertimeFormPreviewRejected(
            'Pratinjau tidak lengkap. Coba lagi.',
          ));
          return;
        }

        emit(OvertimeFormPreviewed(data));
        return;
      }

      emit(OvertimeFormPreviewRejected(
        errorMessageFromResponse(response),
        code: errorCodeFromResponse(response),
      ));
    } catch (e) {
      emit(OvertimeFormPreviewRejected(errorMessage(e), code: errorCode(e)));
    }
  }


  void submit({
    required DateTime startAt,
    required DateTime endAt,
    required String reason,
    String? proofPath,
  }) async {
    try {
      String? proofFileId;

      if (proofPath != null) {
        emit(OvertimeFormSubmitting('Mengunggah bukti...'));
        proofFileId =
            await FileUploadService().upload(proofPath, 'overtime_proof');
      }

      emit(OvertimeFormSubmitting('Mengirim laporan...'));

      final data = <String, dynamic>{
        "startAt": startAt.toUtc().toIso8601String(),
        "endAt": endAt.toUtc().toIso8601String(),
        "reason": reason.trim(),
      };


      if (proofFileId != null) data["proofFileId"] = proofFileId;

      final dio = await DioService.getInstance();
      final response = await dio.post("/me/overtime", data: data);

      debugPrint("laporan lembur: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(OvertimeFormSubmitted(
          'Laporan lembur terkirim ke atasan Anda',
        ));
        return;
      }

      emit(OvertimeFormSubmitError(
        errorMessageFromResponse(response),
        code: errorCodeFromResponse(response),
      ));
    } on FileUploadFailure catch (e) {
      emit(OvertimeFormSubmitError(e.message));
    } catch (e) {
      emit(OvertimeFormSubmitError(errorMessage(e), code: errorCode(e)));
    }
  }

  void reset() => emit(OvertimeFormInitial());
}