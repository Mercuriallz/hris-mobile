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

  /// Id penugasan yang sedang diproses. Dipakai menampilkan pemuatan hanya di
  /// kartu yang diketuk, bukan di seluruh layar — kartu lain tetap terbaca,
  /// dan membaca GPS bisa memakan belasan detik.
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

/// Hasil clock in atau clock out. Sekali pakai — layar menampilkannya lewat
/// listener, lalu cubit langsung memancarkan AttendanceLoaded yang baru.
///
/// Dipisah dari AttendanceLoaded supaya pesannya tidak muncul lagi setiap kali
/// daftar dimuat ulang.
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