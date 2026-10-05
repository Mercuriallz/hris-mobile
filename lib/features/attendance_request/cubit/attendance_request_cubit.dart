import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../../../helper/file_upload_service.dart';
import '../../../helper/location_helper.dart';
import '../model/create_attendance_request_model.dart';
import '../repository/attendance_request_repository.dart';
import 'attendance_request_state.dart';

class AttendanceRequestCubit extends Cubit<AttendanceRequestState> {
  AttendanceRequestCubit() : super(AttendanceRequestInitial());

  void fetchMyRequests() async {
    emit(AttendanceRequestLoading());

    final result = await AttendanceRequestRepository().getMyRequests();

    result.fold(
      (l) => emit(AttendanceRequestError(l)),
      (r) => emit(AttendanceRequestLoaded(r.data ?? [])),
    );
  }

 
  void submit({
    required String employeeShiftId,
    required String type,
    String? proposedClockInAt,
    String? proposedClockOutAt,
    required String reason,
    required String selfiePath,
    DateTime? photoTakenAt,
    bool attachLocation = false,
  }) async {
    if (reason.trim().isEmpty) {
      emit(AttendanceRequestSubmitError('Alasan wajib diisi.'));
      return;
    }

    try {
      emit(AttendanceRequestSubmitting('Mengunggah foto...'));

      final selfieFileId = await FileUploadService().upload(
        selfiePath,
        'attendance_selfie',
      );

      double? latitude;
      double? longitude;

      if (attachLocation) {
        try {
          final location = await LocationService().read();
          latitude = location.latitude;
          longitude = location.longitude;
        } catch (_) {
        
          debugPrint('Lokasi tidak disertakan: gagal dibaca');
        }
      }

      emit(AttendanceRequestSubmitting('Mengirim pengajuan...'));

      final formData = CreateAttendanceRequestModel(
        employeeShiftId: employeeShiftId,
        type: type,
        proposedClockInAt: proposedClockInAt,
        proposedClockOutAt: proposedClockOutAt,
        reason: reason,
        selfieFileId: selfieFileId,
        photoTakenAt: photoTakenAt?.toUtc().toIso8601String(),
        latitude: latitude,
        longitude: longitude,
      );

      final dio = await DioService.getInstance();
      final response = await dio.post(
        "/me/attendance-requests",
        data: formData.toJson(),
      );

      debugPrint("pengajuan koreksi: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(AttendanceRequestSubmitted(
          'Pengajuan terkirim ke atasan Anda',
        ));
        return;
      }

      emit(AttendanceRequestSubmitError(
        errorMessageFromResponse(response),
        code: errorCodeFromResponse(response),
      ));
    } on FileUploadFailure catch (e) {
      emit(AttendanceRequestSubmitError(e.message));
    } catch (e) {
      emit(AttendanceRequestSubmitError(errorMessage(e), code: errorCode(e)));
    }
  }
}