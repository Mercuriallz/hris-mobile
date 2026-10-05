import 'package:equatable/equatable.dart';

import '../model/leave_model.dart';


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


class LeaveFormPreviewRejected extends LeaveFormState {
  final String message;
  final String? code;

  LeaveFormPreviewRejected(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}


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