import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../../../helper/face_embedding_service.dart';
import '../model/face_status_model.dart';
import '../repository/face_repository.dart';
import 'face_enroll_state.dart';

class FaceEnrollCubit extends Cubit<FaceEnrollState> {
  FaceEnrollCubit() : super(FaceEnrollInitial());

  void fetchStatus() async {
    emit(FaceEnrollLoading());

    final result = await FaceRepository().status();

    result.fold(
      (l) => emit(FaceEnrollError(l)),
      (r) => emit(FaceEnrollStatusLoaded(r.data ?? FaceStatusData())),
    );
  }

  /// Menghitung embedding dari foto lalu mendaftarkannya.
  ///
  /// Fotonya dihapus setelah dipakai. Tidak dikirim ke server, tidak disimpan
  /// di HP — yang keluar cuma deret angka hasil perhitungan.
  void enroll(String photoPath) async {
    try {
      emit(FaceEnrollProcessing('Memeriksa wajah...'));

      final embedding =
          await FaceEmbeddingService.instance.embedFromFile(photoPath);

      if (!isPlausibleEmbedding(embedding)) {
        emit(FaceEnrollPhotoError(
          'Hasil perhitungan tidak sah. Coba ambil ulang fotonya.',
        ));
        return;
      }

      emit(FaceEnrollProcessing('Mendaftarkan...'));

      final dio = await DioService.getInstance();
      final response = await dio.post(
        "/me/face/enroll",
        data: {
          "embedding": embedding,
          "modelVersion": kFaceModelVersion,
          // Persetujuan dikirim eksplisit, bukan diasumsikan dari fakta bahwa
          // tombolnya ditekan. Data biometrik butuh izin tercatat menurut UU
          // PDP 27/2022, dan layar sebelum ini yang memintanya.
          "consent": true,
        },
      );

      debugPrint("daftar wajah: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(FaceEnrollSuccess('Wajah berhasil didaftarkan'));
        return;
      }

      emit(FaceEnrollError(errorMessageFromResponse(response)));
    } on FaceFailure catch (e) {
      // Kegagalan foto dibedakan supaya layarnya bisa menawarkan "ambil
      // ulang" alih-alih "coba lagi" — dan keduanya tindakan yang berbeda.
      emit(FaceEnrollPhotoError(e.message));
    } catch (e) {
      emit(FaceEnrollError(errorMessage(e)));
    } finally {
      await deleteTempPhoto(photoPath);
    }
  }

  void reset() => emit(FaceEnrollInitial());
}