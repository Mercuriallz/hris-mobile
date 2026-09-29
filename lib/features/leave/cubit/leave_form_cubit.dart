import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../../../helper/file_upload_service.dart';
import '../model/leave_model.dart';
import 'leave_form_state.dart';

class LeaveFormCubit extends Cubit<LeaveFormState> {
  LeaveFormCubit() : super(LeaveFormInitial());


  void preview({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required bool halfDay,
  }) async {
    emit(LeaveFormPreviewing());

    try {
      final dio = await DioService.getInstance();

      final response = await dio.post(
        "/me/leave/preview",
        data: {
          "leaveTypeId": leaveTypeId,
          "startDate": startDate,
          "endDate": endDate,
          "halfDay": halfDay,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = LeavePreviewResponseModel.fromJson(response.data).data;

        if (data == null) {
          emit(LeaveFormPreviewRejected('Pratinjau tidak lengkap. Coba lagi.'));
          return;
        }

        emit(LeaveFormPreviewed(data));
        return;
      }

      emit(LeaveFormPreviewRejected(
        errorMessageFromResponse(response),
        code: errorCodeFromResponse(response),
      ));
    } catch (e) {
      emit(LeaveFormPreviewRejected(errorMessage(e), code: errorCode(e)));
    }
  }
  void submit({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required bool halfDay,
    required String reason,
    String? attachmentPath,
    String? contactDuringLeave,
  }) async {
    try {
      String? attachmentFileId;

      if (attachmentPath != null) {
        emit(LeaveFormSubmitting('Mengunggah lampiran...'));

        attachmentFileId = await FileUploadService().upload(
          attachmentPath,
          'leave_attachment',
        );
      }

      emit(LeaveFormSubmitting('Mengirim pengajuan...'));

      final formData = CreateLeaveRequestModel(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        halfDay: halfDay,
        reason: reason,
        attachmentFileId: attachmentFileId,
        contactDuringLeave: contactDuringLeave,
      );

      final dio = await DioService.getInstance();
      final response = await dio.post(
        "/me/leave/requests",
        data: formData.toJson(),
      );

      debugPrint("pengajuan cuti: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(LeaveFormSubmitted('Pengajuan cuti terkirim ke atasan Anda'));
        return;
      }

      emit(LeaveFormSubmitError(
        errorMessageFromResponse(response),
        code: errorCodeFromResponse(response),
      ));
    } on FileUploadFailure catch (e) {
      emit(LeaveFormSubmitError(e.message));
    } catch (e) {
      emit(LeaveFormSubmitError(errorMessage(e), code: errorCode(e)));
    }
  }

  void reset() => emit(LeaveFormInitial());
}