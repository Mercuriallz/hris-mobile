import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/shift-swap/presentation/shift_swap_hub_page.dart';
import 'package:intl/intl.dart';

import '../helpers/test_env.dart';

String _isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

Map<String, dynamic> shift(String id, DateTime start, {String name = 'Pagi'}) => {
      'employeeShiftId': id,
      'workDate': _isoDate(start),
      'shiftName': name,
      'shiftCode': 'P',
      'scheduledStart': start.toUtc().toIso8601String(),
      'scheduledEnd': start.add(const Duration(hours: 8)).toUtc().toIso8601String(),
      'status': 'scheduled',
    };

void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  final now = DateTime.now();
  final future1 = DateTime(now.year, now.month, now.day + 2, 8);
  final future2 = DateTime(now.year, now.month, now.day + 3, 14);
  final past = now.subtract(const Duration(hours: 3));

  Map<String, Object? Function(dynamic)> api({
    List<Map<String, dynamic>>? shifts,
    List<Map<String, dynamic>>? requests,
  }) =>
      {
        '/me/attendance/history': (_) => {'data': shifts ?? []},
        '/me/shift-swap': (_) => {'data': requests ?? []},
      };

  for (final b in Brightness.values) {
    testWidgets('hanya shift mendatang + pengajuan saya, 360x640 ${b.name} tanpa overflow', (tester) async {
      useSmallPhone(tester);
      final fake = await installFakeApi(routes({
        ...api(shifts: [
          shift('past', past),
          shift('f1', future1),
          shift('f2', future2, name: 'Siang Panjang Sekali Untuk Gudang Utama'),
          {...shift('noid', future2), 'employeeShiftId': null},
        ], requests: [
          {
            'id': 'r1',
            'isRequester': true,
            'counterpartName': 'Rina Kartika Sari Dewi Lestari',
            'requesterWorkDate': _isoDate(future1),
            'requesterShiftName': 'Pagi',
            'counterpartWorkDate': _isoDate(future2),
            'counterpartShiftName': 'Siang',
            'approvalStatus': 'pending',
          },
          {
            'id': 'r2',
            'isRequester': false,
            'requesterName': 'Doni',
            'requesterWorkDate': _isoDate(future1),
            'approvalStatus': 'rejected',
            'decisionNote': 'Kekurangan orang',
          },
        ]),
      }));
      final errors = await collectFlutterErrors(() async {
        await tester.pumpWidget(wrapApp(const ShiftSwapHubPage(), brightness: b));
        await tester.pumpAndSettle();
      });
      expect(errors, isEmpty);
      final history = fake.requests.firstWhere((r) => r.path == '/me/attendance/history');
      expect(history.queryParameters['from'], _isoDate(now));
      expect(history.queryParameters['to'], _isoDate(now.add(const Duration(days: 45))));

      expect(find.text('SHIFT MENDATANG'), findsOneWidget);
      expect(find.textContaining('Pagi · 08:00–16:00'), findsOneWidget);
      expect(find.textContaining('Siang Panjang'), findsOneWidget);
      // shift lampau dan shift tanpa employeeShiftId disaring
      expect(find.byIcon(Icons.swap_horiz), findsNWidgets(2 + 1)); // 2 kartu shift + 1 InfoRow counterpart
      await tester.scrollUntilVisible(find.text('Alasan: Kekurangan orang'), 200);
      expect(find.text('Tukar dengan Rina Kartika Sari Dewi Lestari'), findsOneWidget);
      expect(find.text('Diajak tukar oleh Doni'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
    });
  }

  testWidgets('tanpa jadwal & tanpa pengajuan → EmptyState + teks kosong', (tester) async {
    await installFakeApi(routes(api()));
    await tester.pumpWidget(wrapApp(const ShiftSwapHubPage()));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada jadwal mendatang'), findsOneWidget);
    expect(find.text('Belum ada pengajuan tukar shift.'), findsOneWidget);
  });

  testWidgets('riwayat jadwal gagal dimuat → ErrorState (bukan "Belum ada jadwal")', (tester) async {
    await installFakeApi(routes({
      '/me/attendance/history': (_) => const FakeReply(400, {'message': 'Rentang tanggal tidak valid'}),
      '/me/shift-swap': (_) => {'data': []},
    }));
    await tester.pumpWidget(wrapApp(const ShiftSwapHubPage()));
    await tester.pumpAndSettle();
    expect(find.text('Rentang tanggal tidak valid'), findsOneWidget);
    expect(find.text('Belum ada jadwal mendatang'), findsNothing);
  });
}
