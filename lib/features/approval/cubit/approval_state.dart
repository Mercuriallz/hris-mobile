import 'package:equatable/equatable.dart';
import 'package:hris_mobile/features/approval/model/approval_model.dart';


abstract class ApprovalState extends Equatable {
  @override
  List<Object> get props => [];
}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class ApprovalLoaded extends ApprovalState {
  final List<ApprovalData> items;

  ApprovalLoaded(this.items);

  @override
  List<Object> get props => [items.map((i) => i.id).join(',')];
}

class ApprovalError extends ApprovalState {
  final String message;

  ApprovalError(this.message);

  @override
  List<Object> get props => [message];
}

/// Sedang mengirim keputusan untuk satu pengajuan.
///
/// Membawa idnya supaya pemuatan cuma muncul di kartu yang diputuskan, bukan
/// di seluruh daftar — penyetuju sering memutuskan beberapa pengajuan
/// berturut-turut.
class ApprovalDeciding extends ApprovalState {
  final String approvalId;

  ApprovalDeciding(this.approvalId);

  @override
  List<Object> get props => [approvalId];
}

class ApprovalDecided extends ApprovalState {
  final String message;

  ApprovalDecided(this.message);

  @override
  List<Object> get props => [message];
}

class ApprovalDecideError extends ApprovalState {
  final String message;

  ApprovalDecideError(this.message);

  @override
  List<Object> get props => [message];
}