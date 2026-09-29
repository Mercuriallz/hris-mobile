import 'package:equatable/equatable.dart';
import 'package:hris_mobile/features/overtime/model/overtime_model.dart';

abstract class OvertimeFormState extends Equatable {
  @override
  List<Object> get props => [];
}

class OvertimeFormInitial extends OvertimeFormState {}

class OvertimeFormPreviewing extends OvertimeFormState {}

class OvertimeFormPreviewed extends OvertimeFormState {
  final OvertimePreviewData preview;

  OvertimeFormPreviewed(this.preview);

  @override
  List<Object> get props => [
        preview.hours ?? 0,
        preview.equivalentHours ?? 0,
        preview.dayType ?? '',
      ];
}


class OvertimeFormPreviewRejected extends OvertimeFormState {
  final String message;
  final String? code;

  OvertimeFormPreviewRejected(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}

class OvertimeFormSubmitting extends OvertimeFormState {
  final String step;

  OvertimeFormSubmitting(this.step);

  @override
  List<Object> get props => [step];
}

class OvertimeFormSubmitted extends OvertimeFormState {
  final String message;

  OvertimeFormSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

class OvertimeFormSubmitError extends OvertimeFormState {
  final String message;
  final String? code;

  OvertimeFormSubmitError(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}