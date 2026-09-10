import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../model/attendance_history_model.dart';
import '../repository/attendance_history_repository.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit() : super(AttendanceHistoryInitial());

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Bulan yang sedang dilihat. Disimpan di cubit, bukan di layar, supaya
  /// tombol geser bulan tidak perlu mengurus tanggalnya sendiri.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void fetchHistory({DateTime? month}) async {
    if (month != null) _month = DateTime(month.year, month.month);

    emit(AttendanceHistoryLoading());

    final from = _dateFormat.format(_month);
    // Hari ke-0 bulan berikutnya adalah hari terakhir bulan ini — cara paling
    // pendek yang benar untuk semua bulan, termasuk Februari kabisat.
    final to = _dateFormat.format(DateTime(_month.year, _month.month + 1, 0));

    final result = await AttendanceHistoryRepository().getHistory(from, to);

    result.fold(
      (l) => emit(AttendanceHistoryError(l)),
      (r) {
        // Backend mengembalikan urutan naik. Riwayat lebih berguna dibaca dari
        // yang terbaru — orang membukanya untuk memeriksa hari-hari terakhir,
        // bukan awal bulan.
        final rows = (r.data ?? []).reversed.toList();

        emit(AttendanceHistoryLoaded(
          rows,
          HistorySummary.from(rows),
          _month,
        ));
      },
    );
  }

  void previousMonth() => fetchHistory(
        month: DateTime(_month.year, _month.month - 1),
      );

  /// Bulan berikutnya dibatasi sampai bulan ini — riwayat masa depan tidak
  /// ada isinya, dan tombol yang selalu bisa ditekan membuat orang menggeser
  /// terus tanpa menemukan apa pun.
  void nextMonth() {
    if (!canGoNext) return;
    fetchHistory(month: DateTime(_month.year, _month.month + 1));
  }

  bool get canGoNext {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    return !next.isAfter(DateTime(now.year, now.month));
  }
}