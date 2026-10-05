import 'package:equatable/equatable.dart';

import '../model/attendance_request_model.dart';

abstract class AttendanceRequestState extends Equatable {
  @override
  List<Object> get props => [];
}

class AttendanceRequestInitial extends AttendanceRequestState {}

class AttendanceRequestLoading extends AttendanceRequestState {}

class AttendanceRequestLoaded extends AttendanceRequestState {
  final List<AttendanceRequestData> requests;

  AttendanceRequestLoaded(this.requests);

  @override
  List<Object> get props =>
      [requests.map((r) => '${r.id}:${r.approvalStatus}').join(',')];
}

class AttendanceRequestError extends AttendanceRequestState {
  final String message;

  AttendanceRequestError(this.message);

  @override
  List<Object> get props => [message];
}

class AttendanceRequestSubmitting extends AttendanceRequestState {
  final String step;

  AttendanceRequestSubmitting(this.step);

  @override
  List<Object> get props => [step];
}

class AttendanceRequestSubmitted extends AttendanceRequestState {
  final String message;

  AttendanceRequestSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

class AttendanceRequestSubmitError extends AttendanceRequestState {
  final String message;
  final String? code;

  AttendanceRequestSubmitError(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}