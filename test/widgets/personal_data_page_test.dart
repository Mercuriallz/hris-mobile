import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/profile/cubit/my_profile_cubit.dart';
import 'package:hris_mobile/features/auth/profile/presentation/personal_data_page.dart';

import '../helpers/test_env.dart';

Map<String, dynamic> me({Object? profile}) => {
      'statusCode': 200,
      'data': {
        'employeeNumber': 'EMP-001',
        'fullName': 'Budi Santoso Wicaksono Pratama',
        'workEmail': 'budi.santoso.wicaksono@perusahaan-panjang.co.id',
        'employmentStatus': 'active',
        'employmentType': 'contract',
        'joinDate': '2024-01-15',
        'contractStartDate': '2024-01-15',
        'contractEndDate': '2026-01-14',
        'jobGrade': null,
        'companyName': 'PT Maju Bersama Sejahtera Abadi Indonesia',
        'departmentName': 'Keuangan',
        'positionTitle': 'Staf Administrasi Keuangan dan Akuntansi Senior',
        'officeLocationName': 'Kantor Pusat',
        'isFlexibleLocation': true,
        'reportsToName': null,
        'photoUrl': null,
        'profile': profile,
      },
    };

const profile = {
  'nationalId': '3201234567890001',
  'taxId': '123456789012345',
  'dateOfBirth': '1998-03-12',
  'birthPlace': 'Bandung',
  'religion': 'protestan',
  'idCardAddress':
      'Jl. Raya Cibaduyut Gang Kelinci No. 123 RT 004 RW 011, Kelurahan Cibaduyut Kidul, Kecamatan Bojongloa Kidul, Kota Bandung, Jawa Barat 40239',
  'bankAccountNumber': '1234567890',
};

void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  Widget page(MyProfileCubit cubit, {Brightness b = Brightness.light}) => BlocProvider.value(
        value: cubit,
        child: wrapApp(const PersonalDataPage(), brightness: b),
      );

  /// Layar setinggi seluruh halaman, supaya semua baris dibangun ListView.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(400 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  Future<MyProfileCubit> load(WidgetTester tester, Object? p, {Brightness b = Brightness.light}) async {
    await installFakeApi(routes({'/me': (_) => me(profile: p)}));
    final cubit = MyProfileCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(page(cubit, b: b));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('nomor tersamar, mata membuka per field, salin menyalin nilai asli', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    useTallScreen(tester);

    await load(tester, profile);

    expect(find.text('3201 •••••••• 0001'), findsOneWidget);
    expect(find.text('3201234567890001'), findsNothing);
    expect(find.text('1234 ••••••• 2345'), findsOneWidget);
    expect(find.text('Bandung, 12 Maret 1998'), findsOneWidget);
    expect(find.text('Kristen Protestan'), findsOneWidget);
    expect(find.text('15 Januari 2024 s/d 14 Januari 2026'), findsOneWidget);

    await tap(tester, find.byTooltip('Tampilkan NIK (KTP)'));
    expect(find.text('3201234567890001'), findsOneWidget);
    // Field lain tetap tersamar.
    expect(find.text('1234 ••••••• 2345'), findsOneWidget);

    await tap(tester, find.byTooltip('Sembunyikan NIK (KTP)'));
    expect(find.text('3201 •••••••• 0001'), findsOneWidget);

    // NPWP dibuka dengan format bertitik.
    await tap(tester, find.byTooltip('Tampilkan NPWP'));
    expect(find.text('12.345.678.9-012.345'), findsOneWidget);

    await tap(tester, find.byTooltip('Salin NIK (KTP)'));
    expect(copied, '3201234567890001');
    expect(find.text('NIK disalin'), findsOneWidget);
  });

  testWidgets('nilai kosong tampil "-" tanpa tombol mata/salin', (tester) async {
    useTallScreen(tester);
    await load(tester, profile);
    // jobGrade, atasan, KK, dll. kosong.
    expect(find.text('-'), findsWidgets);
    expect(find.byTooltip('Tampilkan Nomor Kartu Keluarga'), findsNothing);
    expect(find.byTooltip('Salin Nomor Kartu Keluarga'), findsNothing);
  });

  testWidgets('profile null → data pribadi "-", tanpa tombol mata', (tester) async {
    useTallScreen(tester);
    await load(tester, null);
    expect(find.text('-'), findsAtLeastNWidgets(20));
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(find.text('Budi Santoso Wicaksono Pratama'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Hubungi HR'), 300);
    expect(find.textContaining('Semua data di sini diatur HR'), findsOneWidget);
  });

  testWidgets('gagal → ErrorState, Coba Lagi memuat ulang', (tester) async {
    useTallScreen(tester);
    var calls = 0;
    await installFakeApi((_) {
      calls++;
      return calls == 1 ? const FakeReply(500, {'message': 'Server sibuk'}) : FakeReply(200, me(profile: profile));
    });
    final cubit = MyProfileCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(page(cubit));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Server sibuk'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('3201 •••••••• 0001'), findsOneWidget);
  });

  for (final b in Brightness.values) {
    testWidgets('360x640 ${b.name}, teks besar, semua dibuka: tanpa overflow', (tester) async {
      useSmallPhone(tester, textScale: 1.3);
      final errors = await collectFlutterErrors(() async {
        await load(tester, profile, b: b);
        for (final label in ['NIK (KTP)', 'NPWP', 'Nomor rekening']) {
          await tap(tester, find.byTooltip('Tampilkan $label'));
        }
        await tester.scrollUntilVisible(find.textContaining('Hubungi HR'), 300);
      });
      expect(errors, isEmpty);
      expect(find.byTooltip('Sembunyikan Nomor rekening'), findsOneWidget);
    });
  }
}
