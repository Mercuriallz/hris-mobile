import 'package:equatable/equatable.dart';

import '../model/shift_card_model.dart';

abstract class AttendanceState extends Equatable {
  @override
  List<Object> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<ShiftCard> cards;


  final String? processingShiftId;

  AttendanceLoaded(this.cards, {this.processingShiftId});

  @override
  List<Object> get props => [
        cards.map((c) => '${c.employeeShiftId}:${c.state}').join(','),
        processingShiftId ?? '',
      ];
}

class AttendanceError extends AttendanceState {
  final String message;

  AttendanceError(this.message);

  @override
  List<Object> get props => [message];
}


class AttendanceActionSuccess extends AttendanceState {
  final String message;

  AttendanceActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class AttendanceActionError extends AttendanceState {
  final String message;
  final String? code;

  AttendanceActionError(this.message, {this.code});

  @override
  List<Object> get props => [message, code ?? ''];
}