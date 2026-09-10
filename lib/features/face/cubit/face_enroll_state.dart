import 'package:equatable/equatable.dart';

import '../model/face_status_model.dart';

abstract class FaceEnrollState extends Equatable {
  @override
  List<Object> get props => [];
}

class FaceEnrollInitial extends FaceEnrollState {}

class FaceEnrollLoading extends FaceEnrollState {}

class FaceEnrollStatusLoaded extends FaceEnrollState {
  final FaceStatusData status;

  FaceEnrollStatusLoaded(this.status);

  @override
  List<Object> get props => [
        status.enrolled ?? false,
        status.modelVersion ?? '',
        status.verificationEnabled ?? false,
      ];
}

/// Sedang memproses foto, dengan keterangan langkahnya.
///
/// Menghitung embedding memakan ratusan milidetik dan memuat model bisa lebih
/// lama lagi. Tanpa penanda, orang mengira aplikasinya menggantung.
class FaceEnrollProcessing extends FaceEnrollState {
  final String step;

  FaceEnrollProcessing(this.step);

  @override
  List<Object> get props => [step];
}

class FaceEnrollSuccess extends FaceEnrollState {
  final String message;

  FaceEnrollSuccess(this.message);

  @override
  List<Object> get props => [message];
}

/// Gagal karena fotonya, bukan karena jaringan.
///
/// Dipisah karena tindak lanjutnya berbeda: yang ini perlu foto diulang,
/// sementara kegagalan jaringan perlu dicoba lagi apa adanya.
class FaceEnrollPhotoError extends FaceEnrollState {
  final String message;

  FaceEnrollPhotoError(this.message);

  @override
  List<Object> get props => [message];
}

class FaceEnrollError extends FaceEnrollState {
  final String message;

  FaceEnrollError(this.message);

  @override
  List<Object> get props => [message];
}