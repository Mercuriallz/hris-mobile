import 'package:equatable/equatable.dart';

import '../model/salary_slip_model.dart';

abstract class SalarySlipState extends Equatable {
  @override
  List<Object> get props => [];
}

class SalarySlipInitial extends SalarySlipState {}

class SalarySlipLoading extends SalarySlipState {}

class SalarySlipLoaded extends SalarySlipState {
  final List<SalarySlip> slips;

  SalarySlipLoaded(this.slips);

  @override
  List<Object> get props => [slips.map((s) => '${s.id}:${s.takeHomePay}').join(',')];
}

class SalarySlipError extends SalarySlipState {
  final String message;

  SalarySlipError(this.message);

  @override
  List<Object> get props => [message];
}
