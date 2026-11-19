import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/session_events.dart';

import '../repository/salary_slip_repository.dart';
import 'salary_slip_state.dart';

class SalarySlipCubit extends Cubit<SalarySlipState> {
  SalarySlipCubit() : super(SalarySlipInitial()) {
    // Data pribadi: dikosongkan begitu sesi berakhir.
    _sessionSub = SessionEvents.cleared.listen((_) => reset());
  }

  late final StreamSubscription<void> _sessionSub;

  Future<void> fetch({bool silent = false}) async {
    if (!silent) emit(SalarySlipLoading());
    final result = await SalarySlipRepository().getMine();
    result.fold(
      (l) => silent ? null : emit(SalarySlipError(l)),
      (r) {
        // Terbaru di atas, apa pun urutan dari server.
        final sorted = [...r]..sort((a, b) => b.month.compareTo(a.month));
        emit(SalarySlipLoaded(sorted));
      },
    );
  }

  void reset() {
    if (!isClosed) emit(SalarySlipInitial());
  }

  @override
  Future<void> close() {
    _sessionSub.cancel();
    return super.close();
  }
}
