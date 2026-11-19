import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/cubit/salary_slip_cubit.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_detail_page.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_page.dart';
import 'package:hris_mobile/features/shift-swap/presentation/shift_swap_hub_page.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_cubit.dart';
import 'package:hris_mobile/features/warning_letter/presentation/warning_letter_detail_page.dart';
import 'package:hris_mobile/features/warning_letter/presentation/warning_letter_page.dart';

import '../helpers/test_env.dart';

/// Ukuran teks aksesibilitas 130% di layar 360x640, untuk halaman yang
/// tidak punya Row berisiko (lihat common_widgets_test untuk yang punya).
void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  final future = DateTime.now().add(const Duration(days: 2));
  final handler = routes({
    '/me/salary-slips': (_) => {
          'data': [
            {'id': 's1', 'month': '2026-10', 'startDate': '2026-10-01', 'endDate': '2026-10-31', 'netPay': '123456789'}
          ]
        },
    '/me/salary-slips/s1': (_) => {
          'data': {
            'id': 's1',
            'month': '2026-10',
            'startDate': '2026-10-01',
            'endDate': '2026-10-31',
            'netPay': '123456789',
            'grossPay': '150000000',
            'totalDeduction': '26543211',
            'lwpDays': 2,
            'bankName': 'Bank Pembangunan Daerah Jawa Barat dan Banten',
            'bankAccountNumber': '1234567890',
            'lines': {
              'earnings': [
                {'name': 'Tunjangan Kinerja Individu Triwulanan Tambahan', 'amount': '150000000'}
              ],
              'deductions': [
                {'name': 'PPh 21', 'amount': '26543211'}
              ],
            },
          }
        },
    '/me/warning-letters': (_) => {
          'data': [
            {'id': 'w1', 'level': 'sp2', 'status': 'active', 'issuedDate': '2026-10-01', 'expiresDate': '2027-04-01', 'violation': 'V'},
          ]
        },
    '/me/warning-letters/w1': (_) => {
          'data': {'id': 'w1', 'level': 'sp1', 'status': 'active', 'issuedDate': '2026-10-01', 'expiresDate': '2027-04-01', 'violation': 'V', 'letterNumber': '001/SP-1/HRD/PT-CONTOH-SEJAHTERA/X/2026'}
        },
    '/me/attendance/history': (_) => {
          'data': [
            {'employeeShiftId': 'e', 'workDate': '2026-12-31', 'shiftName': 'Shift Malam Gudang Distribusi Regional', 'scheduledStart': future.toUtc().toIso8601String()}
          ]
        },
    '/me/shift-swap': (_) => {
          'data': [
            {'id': 'r', 'isRequester': true, 'counterpartName': 'Muhammad Rizky Ananda Pratama Wijaya', 'approvalStatus': 'cancelled', 'requesterWorkDate': '2026-12-31'}
          ]
        },
  });

  final pages = <String, Widget Function()>{
    'SalarySlipPage': () => BlocProvider(create: (_) => SalarySlipCubit(), child: const SalarySlipPage()),
    'SalarySlipDetailPage': () => const SalarySlipDetailPage(slipId: 's1'),
    'WarningLetterPage': () => BlocProvider(create: (_) => WarningLetterCubit(), child: const WarningLetterPage()),
    'WarningLetterDetailPage': () =>
        BlocProvider(create: (_) => WarningLetterCubit(), child: const WarningLetterDetailPage(letterId: 'w1')),
    'ShiftSwapHubPage': () => const ShiftSwapHubPage(),
  };

  for (final e in pages.entries) {
    for (final b in Brightness.values) {
      testWidgets('${e.key} teks 130% ${b.name}: tanpa overflow', (tester) async {
        useSmallPhone(tester, textScale: 1.3);
        await installFakeApi(handler);
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(wrapApp(e.value(), brightness: b));
          await tester.pumpAndSettle();
          for (var i = 0; i < 6; i++) {
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
            await tester.pumpAndSettle();
          }
        });
        expect(errors, isEmpty);
      });
    }
  }
}
