import 'package:equatable/equatable.dart';
import 'package:hris_mobile/features/overtime/model/overtime_model.dart';


abstract class OvertimeState extends Equatable {
  @override
  List<Object> get props => [];
}

class OvertimeInitial extends OvertimeState {}

class OvertimeLoading extends OvertimeState {}

class OvertimeLoaded extends OvertimeState {
  final List<OvertimeRequestData> requests;

  OvertimeLoaded(this.requests);

  @override
  List<Object> get props =>
      [requests.map((r) => '${r.id}:${r.approvalStatus}').join(',')];
}

class OvertimeError extends OvertimeState {
  final String message;

  OvertimeError(this.message);

  @override
  List<Object> get props => [message];
}