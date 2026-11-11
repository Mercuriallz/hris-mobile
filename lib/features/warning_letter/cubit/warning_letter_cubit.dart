import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/warning_letter_repository.dart';
import 'warning_letter_state.dart';

class WarningLetterCubit extends Cubit<WarningLetterState> {
  WarningLetterCubit() : super(WarningLetterInitial());

  /// Jumlah surat yang belum dibuka, untuk penanda di menu Profil.
  int get unreadCount {
    final s = state;
    if (s is! WarningLetterLoaded) return 0;
    return s.letters.where((l) => l.isUnread).length;
  }

  Future<void> fetch({bool silent = false}) async {
    if (!silent) emit(WarningLetterLoading());
    final result = await WarningLetterRepository().getMine();
    result.fold(
      (l) => silent ? null : emit(WarningLetterError(l)),
      (r) => emit(WarningLetterLoaded(r)),
    );
  }

  /// Dipanggil setelah detail dibuka, supaya penanda belum-dibaca hilang
  /// tanpa memuat ulang seluruh daftar.
  void markViewed(String id) {
    final s = state;
    if (s is! WarningLetterLoaded) return;
    emit(WarningLetterLoaded([
      for (final l in s.letters) l.id == id ? l.markViewed() : l,
    ]));
  }

  void reset() => emit(WarningLetterInitial());
}

