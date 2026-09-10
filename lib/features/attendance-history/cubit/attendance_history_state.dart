import 'package:equatable/equatable.dart';

import '../model/attendance_history_model.dart';

abstract class AttendanceHistoryState extends Equatable {
  @override
  List<Object> get props => [];
}

class AttendanceHistoryInitial extends AttendanceHistoryState {}

class AttendanceHistoryLoading extends AttendanceHistoryState {}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceHistoryData> rows;
  final HistorySummary summary;

  /// Bulan yang sedang ditampilkan, dipakai judul dan tombol geser bulan.
  final DateTime month;

  AttendanceHistoryLoaded(this.rows, this.summary, this.month);

  @override
  List<Object> get props => [
        month,
        rows.map((r) => '${r.workDate}:${r.status}').join(','),
      ];
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;

  AttendanceHistoryError(this.message);

  @override
  List<Object> get props => [message];
}