import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/cubit/salary_slip_cubit.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_detail_page.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_page.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_widgets.dart';

import '../helpers/test_env.dart';

Map<String, dynamic> slip(String id, String month, {Object net = '8630000'}) => {
      'id': id,
      'month': month,
      'startDate': '$month-01',
      'endDate': '$month-28',
      'netPay': net,
    };

Map<String, dynamic> detail({Map<String, dynamic> extra = const {}}) => {
      'id': 's1',
      'month': '2026-10',
      'startDate': '2026-10-01',
      'endDate': '2026-10-31',
      'positionTitle': 'Staf Administrasi Keuangan dan Akuntansi Senior',
      'departmentName': 'Keuangan',
      'bankName': 'Bank Rakyat Indonesia',
      'bankAccountNumber': '0123 4567 8901 2345',
      'totalWorkingDays': 22,
      'paymentDays': '21.5',
      'lwpDays': '0.5',
      'grossPay': '9000000',
      'totalDeduction': '370000',
      'totalEmployerContribution': '450000',
      'netPay': '8630000',
      'roundedNetPay': '8630000',
      'lines': {
        'earnings': [
          {'componentId': 'e1', 'name': 'Gaji Pokok', 'amount': '8000000'},
          {'componentId': 'e2', 'name': 'Tunjangan Transportasi dan Komunikasi Bulanan', 'amount': '1000000'},
          {'componentId': 'e3', 'name': 'Basis BPJS', 'amount': '5000000', 'statistical': true},
        ],
        'deductions': [
          {'componentId': 'd1', 'name': 'BPJS Kesehatan', 'amount': '100000'},
          {'componentId': 'd2', 'name': 'PPh 21', 'amount': '270000'},
        ],
        'employerContributions': [
          {'componentId': 'c1', 'name': 'BPJS JKK', 'amount': '450000'},
        ],
      },
      ...extra,
    };

void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  Widget listPage(SalarySlipCubit cubit, {Brightness b = Brightness.light}) => BlocProvider.value(
        value: cubit,
        child: wrapApp(const SalarySlipPage(), brightness: b),
      );

  group('SalarySlipPage', () {
    testWidgets('memuat, urut terbaru, nominal tersembunyi lalu bisa ditampilkan', (tester) async {
      await installFakeApi(routes({
        '/me/salary-slips': (_) => {
              'data': [slip('a', '2026-08'), slip('b', '2026-10'), slip('c', '2026-09')]
            },
      }));
      final cubit = SalarySlipCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(listPage(cubit));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      final months = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((d) => d != null && d.endsWith('2026') && !d.contains('–'))
          .toList();
      expect(months, ['Oktober 2026', 'September 2026', 'Agustus 2026']);
      expect(find.text(kHiddenAmount), findsNWidgets(3));
      expect(find.text('Rp 8.630.000'), findsNothing);

      await tester.tap(find.byTooltip('Tampilkan nominal'));
      await tester.pump();
      expect(find.text('Rp 8.630.000'), findsNWidgets(3));
      expect(find.byTooltip('Sembunyikan nominal'), findsOneWidget);
    });

    testWidgets('kosong → EmptyState', (tester) async {
      await installFakeApi((_) => const FakeReply(200, {'data': []}));
      final cubit = SalarySlipCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(listPage(cubit));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada slip gaji'), findsOneWidget);
    });

    testWidgets('gagal → ErrorState, Coba Lagi memuat ulang', (tester) async {
      var calls = 0;
      await installFakeApi((_) {
        calls++;
        return calls == 1
            ? const FakeReply(400, {'message': 'Akun belum terhubung ke karyawan'})
            : FakeReply(200, {'data': [slip('a', '2026-10')]});
      });
      final cubit = SalarySlipCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(listPage(cubit));
      await tester.pumpAndSettle();
      expect(find.text('Akun belum terhubung ke karyawan'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Oktober 2026'), findsOneWidget);
    });

    for (final b in Brightness.values) {
      testWidgets('360x640 ${b.name}, nominal besar ditampilkan: tanpa overflow', (tester) async {
        useSmallPhone(tester);
        await installFakeApi((_) => FakeReply(200, {
              'data': [for (var m = 1; m <= 12; m++) slip('s$m', '2025-${m.toString().padLeft(2, '0')}', net: '1234567890')]
            }));
        final cubit = SalarySlipCubit();
        addTearDown(cubit.close);
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(listPage(cubit, b: b));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Tampilkan nominal'));
          await tester.pumpAndSettle();
        });
        expect(errors, isEmpty);
        expect(find.text('Desember 2025'), findsOneWidget);
      });
    }
  });

  group('SalarySlipDetailPage', () {
    for (final b in Brightness.values) {
      testWidgets('rincian lengkap, rekening disamarkan, 360x640 ${b.name} tanpa overflow', (tester) async {
        useSmallPhone(tester);
        final api = await installFakeApi(routes({'/me/salary-slips/s1': (_) => {'data': detail()}}));
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(wrapApp(const SalarySlipDetailPage(slipId: 's1'), brightness: b));
          await tester.pumpAndSettle();
        });
        expect(errors, isEmpty);
        expect(api.requests.single.path, '/me/salary-slips/s1');
        expect(find.text('Oktober 2026'), findsOneWidget); // judul AppBar
        expect(find.text('Rp 8.630.000'), findsOneWidget);
        expect(find.text('Ada 0,5 hari cuti tidak dibayar di periode ini.'), findsOneWidget);
        expect(find.text('komponen bantu, tidak dibayarkan'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('- Rp 370.000'), 200);
        await tester.scrollUntilVisible(find.text('DITANGGUNG PERUSAHAAN'), 200);
        await tester.scrollUntilVisible(find.text('Rekening tujuan'), 200);
        expect(find.text('Bank Rakyat Indonesia · •••• 2345'), findsOneWidget);
        expect(find.textContaining('0123 4567'), findsNothing);
        expect(find.text('21,5 dari 22 hari kerja'), findsOneWidget);
        expect(find.text('Lihat Slip (PDF)'), findsOneWidget);
      });
    }

    testWidgets('tanpa cuti tak dibayar & kontribusi perusahaan hanya komponen bantu → bagian disembunyikan',
        (tester) async {
      await installFakeApi(routes({
        '/me/salary-slips/s1': (_) => {
              'data': detail(extra: {
                'lwpDays': 0,
                'bankName': '',
                'bankAccountNumber': '',
                'lines': {
                  'earnings': [],
                  'deductions': [],
                  'employerContributions': [
                    {'name': 'Basis', 'amount': 1, 'excludedFromTotal': true}
                  ],
                },
              })
            },
      }));
      await tester.pumpWidget(wrapApp(const SalarySlipDetailPage(slipId: 's1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('cuti tidak dibayar'), findsNothing);
      expect(find.text('DITANGGUNG PERUSAHAAN'), findsNothing);
      expect(find.text('Tidak ada'), findsNWidgets(2));
      await tester.scrollUntilVisible(find.text('Rekening tujuan'), 200);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('404 → ErrorState dengan pesan server', (tester) async {
      await installFakeApi((_) => const FakeReply(404, {'message': 'Slip gaji tidak ditemukan'}));
      await tester.pumpWidget(wrapApp(const SalarySlipDetailPage(slipId: 'zzz')));
      await tester.pumpAndSettle();
      expect(find.text('Slip gaji tidak ditemukan'), findsOneWidget);
      expect(find.text('Slip Gaji'), findsOneWidget);
    });
  });
}
