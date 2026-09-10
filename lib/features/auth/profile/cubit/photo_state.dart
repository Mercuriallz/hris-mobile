import 'package:equatable/equatable.dart';

abstract class PhotoState extends Equatable {
  @override
  List<Object> get props => [];
}

class PhotoInitial extends PhotoState {}

/// Sedang mengunggah, dengan keterangan langkahnya.
///
/// Unggahan foto di jaringan seluler bisa memakan belasan detik. Tanpa
/// penanda, orang mengira aplikasinya menggantung dan menekan tombolnya lagi.
class PhotoUploading extends PhotoState {
  final String step;

  PhotoUploading(this.step);

  @override
  List<Object> get props => [step];
}

class PhotoUploaded extends PhotoState {
  final String? photoUrl;

  PhotoUploaded(this.photoUrl);

  @override
  List<Object> get props => [photoUrl ?? ''];
}

class PhotoError extends PhotoState {
  final String message;

  PhotoError(this.message);

  @override
  List<Object> get props => [message];
}