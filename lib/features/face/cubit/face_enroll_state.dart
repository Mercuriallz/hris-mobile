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