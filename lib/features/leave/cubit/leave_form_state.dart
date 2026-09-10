import 'package:equatable/equatable.dart';

import '../model/leave_model.dart';

/// State formulir dipisah dari state daftar.
///
/// Kalau disatukan, menghitung pratinjau akan menimpa state daftar — dan
/// daftar di belakang formulir berkedip kosong setiap kali orang mengubah
/// tanggal.
abstract class LeaveFormState extends Equatable {
  @override
  List<Object> get props => [];
}

class LeaveFormInitial extends LeaveFormState {}

/// Sedang menghitung pratinjau.
class LeaveFormPreviewing extends LeaveFormState {}

class LeaveFormPreviewed extends LeaveFormState {
  final LeavePreviewData preview;

  LeaveFormPreviewed(this.preview);

  @override
  List<Object> get props => [
        preview.workingDays ?? 0,
        preview.paidDays ?? 0,
        preview.unpaidDays ?? 0,
      ];
}

/// Pratinjau ditolak — mis. tidak ada hari kerja di rentang itu, atau sisa
/// jatah tidak cukup.
///
/// Dipisah dari kegagalan pengiriman karena artinya berbeda: ini berarti
/// pengajuannya belum sah, bukan bahwa pengirimannya gagal.
class LeaveFormPreviewRejected extends LeaveFormState {
  final String message;
  final String? code;

  LeaveFormPreviewRejected(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}

/// Sedang mengirim, dengan keterangan langkahnya.
///
/// Unggahan lampiran bisa memakan belasan detik di jaringan seluler — tanpa
/// penanda, orang mengira aplikasinya menggantung dan menekan tombolnya lagi.
class LeaveFormSubmitting extends LeaveFormState {
  final String step;

  LeaveFormSubmitting(this.step);

  @override
  List<Object> get props => [step];
}

class LeaveFormSubmitted extends LeaveFormState {
  final String message;

  LeaveFormSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

class LeaveFormSubmitError extends LeaveFormState {
  final String message;
  final String? code;

  LeaveFormSubmitError(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}