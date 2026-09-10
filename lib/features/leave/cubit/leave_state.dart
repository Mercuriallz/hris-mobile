import 'package:equatable/equatable.dart';

import '../model/leave_model.dart';

abstract class LeaveState extends Equatable {
  @override
  List<Object> get props => [];
}

class LeaveInitial extends LeaveState {}

class LeaveLoading extends LeaveState {}

class LeaveLoaded extends LeaveState {
  final LeaveBalanceData balance;
  final List<LeaveTypeData> types;
  final List<LeaveRequestData> requests;

  LeaveLoaded(this.balance, this.types, this.requests);

  @override
  List<Object> get props => [
        balance.remaining ?? 0,
        types.length,
        requests.map((r) => '${r.id}:${r.approvalStatus}').join(','),
      ];
}

class LeaveError extends LeaveState {
  final String message;

  LeaveError(this.message);

  @override
  List<Object> get props => [message];
}