import 'package:equatable/equatable.dart';

import '../model/approval_detail_model.dart';

abstract class ApprovalDetailState extends Equatable {
  @override
  List<Object> get props => [];
}

class ApprovalDetailInitial extends ApprovalDetailState {}

class ApprovalDetailLoading extends ApprovalDetailState {}

class ApprovalDetailLoaded extends ApprovalDetailState {
  final ApprovalSummary approval;
  final ApprovalDetail detail;

  ApprovalDetailLoaded(this.approval, this.detail);

  @override
  List<Object> get props => [approval.id ?? '', detail.title ?? ''];
}

class ApprovalDetailError extends ApprovalDetailState {
  final String message;

  ApprovalDetailError(this.message);

  @override
  List<Object> get props => [message];
}