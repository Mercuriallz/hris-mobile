import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/helper/location_helper.dart';
import 'package:hris_mobile/utils/device_id_service.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../../../helper/face_embedding_service.dart';
import '../model/shift_card_model.dart';
import '../repository/attendance_repository.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit() : super(AttendanceInitial());

  /// [silent] dipakai setelah clock in berhasil — tanpa itu layar berkedip
  /// kosong sebelum daftar barunya muncul.
  void fetchShifts({bool silent = false}) async {
    if (!silent) emit(AttendanceLoading());

    final result = await AttendanceRepository().myShifts();

    result.fold(
      (l) => emit(AttendanceError(l)),
      (r) => emit(AttendanceLoaded(r.data ?? [])),
    );
  }

  /// [photoPath] hanya diisi kalau verifikasi wajah dinyalakan.
  ///
  /// Fotonya dipakai menghitung embedding di HP lalu dihapus — tidak dikirim
  /// ke server dan tidak disimpan di mana pun. Yang keluar dari HP cuma deret
  /// angka hasil perhitungan.
  void clockIn(String employeeShiftId, {String? photoPath}) => _clock(
        employeeShiftId,
        path: "/me/attendance/clock-in",
        successMessage: "Clock in berhasil dicatat",
        photoPath: photoPath,
      );

  void clockOut(String employeeShiftId, {String? photoPath}) => _clock(
        employeeShiftId,
        path: "/me/attendance/clock-out",
        successMessage: "Clock out berhasil dicatat",
        photoPath: photoPath,
      );

  /// Clock in dan clock out payload-nya identik, jadi jalurnya satu.
  ///
  /// Lokasi dibaca DI SINI, bukan diteruskan dari layar. Dengan begitu tidak
  /// ada celah antara pembacaan dan pengiriman yang bisa dipakai mengirim
  /// koordinat lama — dan layarnya tidak perlu tahu apa pun soal GPS.
  void _clock(
    String employeeShiftId, {
    required String path,
    required String successMessage,
    String? photoPath,
  }) async {
    // Kartu yang sedang tampil disimpan supaya bisa dipancarkan ulang dengan
    // penanda sedang diproses. Tanpa ini, daftarnya hilang selama GPS dibaca —
    // dan membaca GPS bisa memakan belasan detik.
    final currentCards = state is AttendanceLoaded
        ? (state as AttendanceLoaded).cards
        : <ShiftCard>[];

    emit(AttendanceLoaded(currentCards, processingShiftId: employeeShiftId));

    try {
      /// Embedding dihitung SEBELUM GPS dibaca.
      ///
      /// Kalau wajahnya tidak terdeteksi, absensinya batal — jadi membaca GPS
      /// lebih dulu berarti menunggu belasan detik untuk sesuatu yang tidak
      /// akan dipakai. Dan pesan "wajah tidak terdeteksi" yang muncul setelah
      /// menunggu GPS terasa jauh lebih lambat daripada yang muncul langsung.
      List<double>? embedding;

      if (photoPath != null) {
        embedding =
            await FaceEmbeddingService.instance.embedFromFile(photoPath);

        if (!isPlausibleEmbedding(embedding)) {
          emit(AttendanceActionError(
            'Hasil perhitungan wajah tidak sah. Coba ambil ulang fotonya.',
          ));
          emit(AttendanceLoaded(currentCards));
          return;
        }
      }

      final location = await LocationService().read();
      final deviceId = await DeviceIdService().get();
      final dio = await DioService.getInstance();

      final response = await dio.post(
        path,
        data: {
          "employeeShiftId": employeeShiftId,
          "deviceId": deviceId,
          "latitude": location.latitude,
          "longitude": location.longitude,
          "accuracy": location.accuracy,
          "isMocked": location.isMocked,
       
          "faceEmbedding": ?embedding,
          if (embedding != null) "faceModelVersion": kFaceModelVersion,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("$path berhasil untuk $employeeShiftId");

        emit(AttendanceActionSuccess(successMessage));

       
        fetchShifts(silent: true);
        return;
      }

      emit(AttendanceActionError(
        errorMessageFromResponse(response),
        code: errorCodeFromResponse(response),
      ));

      emit(AttendanceLoaded(currentCards));
    } on FaceFailure catch (e) {
     
      emit(AttendanceActionError(e.message, code: e.reason.name));
      emit(AttendanceLoaded(currentCards));
    } catch (e) {
      emit(AttendanceActionError(errorMessage(e), code: errorCode(e)));
      emit(AttendanceLoaded(currentCards));
    } finally {
   
      if (photoPath != null) await deleteTempPhoto(photoPath);
    }
  }
}