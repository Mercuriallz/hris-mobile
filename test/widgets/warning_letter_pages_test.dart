import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_cubit.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_state.dart';
import 'package:hris_mobile/features/warning_letter/model/warning_letter_model.dart';
import 'package:hris_mobile/features/warning_letter/presentation/warning_letter_detail_page.dart';
import 'package:hris_mobile/features/warning_letter/presentation/warning_letter_page.dart';

import '../helpers/test_env.dart';

Map<String, dynamic> letter(
  String id, {
  String level = 'sp1',
  String status = 'active',
  String? viewedAt,
  Map<String, dynamic> extra = const {},
}) =>
    {
      'id': id,
      'level': level,
      'letterNumber': '00$id/HR/X/2026',
      'issuedDate': '2026-10-01',
      'expiresDate': '2027-04-01',
      'violation': 'Pelanggaran $id',
      'detail': 'Rincian pelanggaran $id yang cukup panjang untuk dibaca karyawan.',
      'status': status,
      'viewedAt': viewedAt,
      'companyName': 'PT Contoh Sejahtera',
      ...extra,
    };

void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  Widget listPage(WarningLetterCubit c, {Brightness b = Brightness.light}) =>
      BlocProvider.value(value: c, child: wrapApp(const WarningLetterPage(), brightness: b));

  group('WarningLetterPage', () {
    for (final b in Brightness.values) {
      testWidgets('aktif di atas, riwayat terpisah, ringkasan tingkat tertinggi (360x640 ${b.name})',
          (tester) async {
        useSmallPhone(tester);
        await installFakeApi(routes({
          '/me/warning-letters': (_) => {
                'data': [
                  letter('1', level: 'verbal'),
                  letter('2', level: 'sp2', viewedAt: '2026-10-02'),
                  letter('3', level: 'sp3', status: 'revoked', viewedAt: 'x'),
                  letter('4', level: 'sp1', status: 'expired', viewedAt: 'x'),
                ]
              },
        }));
        final cubit = WarningLetterCubit();
        addTearDown(cubit.close);
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(listPage(cubit, b: b));
          await tester.pumpAndSettle();
        });
        expect(errors, isEmpty);
        expect(find.text('Sedang berlaku: SP 2'), findsOneWidget);
        expect(find.text('MASIH BERLAKU'), findsOneWidget);
        expect(find.text('Baru'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('RIWAYAT'), 200);
        await tester.scrollUntilVisible(find.text('Dicabut'), 200);
        expect(cubit.unreadCount, 1);
      });
    }

    testWidgets('tidak ada surat aktif → ringkasan hijau', (tester) async {
      await installFakeApi((_) => FakeReply(200, {
            'data': [letter('9', status: 'improved', level: 'sp3', viewedAt: 'x')]
          }));
      final cubit = WarningLetterCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(listPage(cubit));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada teguran atau SP yang sedang berlaku.'), findsOneWidget);
      expect(find.text('MASIH BERLAKU'), findsNothing);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('kosong → EmptyState', (tester) async {
      await installFakeApi((_) => const FakeReply(200, {'data': []}));
      final cubit = WarningLetterCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(listPage(cubit));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada surat'), findsOneWidget);
    });

    testWidgets('gagal → ErrorState', (tester) async {
      await installFakeApi((_) => const FakeReply(403, {'message': 'Akses ditolak'}));
      final cubit = WarningLetterCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(listPage(cubit));
      await tester.pumpAndSettle();
      expect(find.text('Akses ditolak'), findsOneWidget);
    });

    testWidgets('tanggal rusak dari server tidak boleh membuat layar error merah', (tester) async {
      await installFakeApi((_) => FakeReply(200, {
            'data': [letter('1', extra: {'expiresDate': '01/04/2027'})]
          }));
      final cubit = WarningLetterCubit();
      addTearDown(cubit.close);
      final errors = await collectFlutterErrors(() async {
        await tester.pumpWidget(listPage(cubit));
        await tester.pumpAndSettle();
      });
      expect(errors, isEmpty);
    });
  });

  group('WarningLetterDetailPage', () {
    Widget detailPage(WarningLetterCubit c, String id, {Brightness b = Brightness.light}) =>
        BlocProvider.value(value: c, child: wrapApp(WarningLetterDetailPage(letterId: id), brightness: b));

    for (final b in Brightness.values) {
      testWidgets('membuka detail menandai surat terbaca di cubit (360x640 ${b.name})', (tester) async {
        useSmallPhone(tester);
        final api = await installFakeApi(routes({
          '/me/warning-letters/1': (_) => {'data': letter('1', level: 'sp2', viewedAt: '2026-11-19T00:00:00Z')},
        }));
        final cubit = WarningLetterCubit()
          ..emit(WarningLetterLoaded([WarningLetter.fromJson(letter('1')), WarningLetter.fromJson(letter('2'))]));
        addTearDown(cubit.close);
        expect(cubit.unreadCount, 2);
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(detailPage(cubit, '1', b: b));
          await tester.pumpAndSettle();
        });
        expect(errors, isEmpty);
        expect(api.requests.single.path, '/me/warning-letters/1');
        expect(cubit.unreadCount, 1);
        expect(find.text('SP 2'), findsWidgets);
        expect(find.text('Pelanggaran 1'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Berlaku sampai'), 200);
        expect(find.text('1 Apr 2027'), findsOneWidget);
        await tester.scrollUntilVisible(
            find.text('Kalau terjadi pelanggaran lagi sebelum SP 2 berakhir, HR akan memberikan SP 3.'), 200);
      });
    }

    final notices = {
      'revoked': 'Surat ini sudah dicabut HR',
      'improved': 'Evaluasi selesai: ada perbaikan',
      'terminated': 'Evaluasi selesai: hubungan kerja diakhiri',
      'evaluation_due': 'Masa evaluasi sudah selesai',
    };
    notices.forEach((status, title) {
      testWidgets('status $status → pemberitahuan "$title"', (tester) async {
        useSmallPhone(tester);
        await installFakeApi(routes({
          '/me/warning-letters/x': (_) => {
                'data': letter('x', level: 'sp3', status: status, viewedAt: 'x', extra: {
                  'revokedReason': 'Salah input',
                  'evaluationNote': 'Catatan evaluasi',
                })
              },
        }));
        final cubit = WarningLetterCubit();
        addTearDown(cubit.close);
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(detailPage(cubit, 'x'));
          await tester.pumpAndSettle();
        });
        expect(errors, isEmpty);
        expect(find.text(title), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Akhir masa evaluasi'), 200);
      });
    });

    testWidgets('404 → ErrorState, cubit tidak berubah', (tester) async {
      await installFakeApi((_) => const FakeReply(404, {'message': 'Surat tidak ditemukan'}));
      final cubit = WarningLetterCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(detailPage(cubit, 'nope'));
      await tester.pumpAndSettle();
      expect(find.text('Surat tidak ditemukan'), findsOneWidget);
      expect(cubit.state, isA<WarningLetterInitial>());
    });
  });
}
