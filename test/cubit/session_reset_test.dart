import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/cubit/salary_slip_cubit.dart';
import 'package:hris_mobile/features/salary_slip/cubit/salary_slip_state.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_cubit.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_state.dart';
import 'package:hris_mobile/helper/session_events.dart';

/// Data pribadi akun sebelumnya tidak boleh tertinggal setelah sesi berakhir.
void main() {
  test('sesi berakhir → Surat dari HR dan slip gaji dikosongkan', () async {
    final letters = WarningLetterCubit();
    final slips = SalarySlipCubit();
    addTearDown(letters.close);
    addTearDown(slips.close);

    letters.emit(WarningLetterLoaded(const []));
    slips.emit(SalarySlipLoaded(const []));

    SessionEvents.notifyCleared();
    await Future<void>.delayed(Duration.zero);

    expect(letters.state, isA<WarningLetterInitial>());
    expect(slips.state, isA<SalarySlipInitial>());
  });

  test('cubit yang sudah ditutup tidak error saat sesi berakhir', () async {
    final letters = WarningLetterCubit();
    await letters.close();
    SessionEvents.notifyCleared();
    await Future<void>.delayed(Duration.zero);
  });
}
