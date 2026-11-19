import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/salary_slip_repository.dart';
import 'salary_slip_state.dart';

class SalarySlipCubit extends Cubit<SalarySlipState> {
  SalarySlipCubit() : super(SalarySlipInitial());

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

  void reset() => emit(SalarySlipInitial());
}
