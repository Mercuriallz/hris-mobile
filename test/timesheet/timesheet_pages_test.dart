import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/timesheet/presentation/timesheet_form_page.dart';
import 'package:hris_mobile/helper/error_message.dart';
import 'package:hris_mobile/helper/location_helper.dart';
import 'package:hris_mobile/features/timesheet/presentation/timesheet_page.dart';

import '../helpers/test_env.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic> row(String id, String title, DateTime date,
    {String start = '09:00',
    String end = '10:30',
    int mins = 90,
    String vis = 'private',
    String? output,
    String? approved,
    String shift = 'non_shift',
    String who = 'QA Karyawan Satu',
    String loc = 'Office',
    String type = 'Rutin'}) =>
    {
      'id': id,
      'employeeName': who,
      'departmentName': 'Teknologi Informasi',
      'title': title,
      'output': output,
      'workDate': _iso(date),
      'startTime': start,
      'endTime': end,
      'durationMinutes': mins,
      'shiftMode': shift,
      'workLocation': loc,
      'workType': type,
      'approvedBy': approved,
      'visibility': vis,
    };

Map<String, dynamic> page(List<Map<String, dynamic>> rows) => {
      'statusCode': 200,
      'data': {
        'data': rows,
        'meta': {'page': 1, 'limit': 30, 'total': rows.length, 'totalPages': 1},
      },
    };

Future<LocationReading> _noGps() async => throw const LocationFailure('GPS mati', code: 'x');

/// Galat pemuatan font Google di lingkungan uji bukan galat tata letak.
Future<List<String>> layoutErrors(Future<void> Function() body) async =>
    (await collectFlutterErrors(body)).where((e) => !e.contains('GoogleFonts')).toList();

void main() {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final older = now.subtract(const Duration(days: 9));

  final mine = [
    row('1', 'Menyusun laporan mingguan dan merapikan data timesheet seluruh tim', now,
        start: '13:00', end: '15:30', mins: 150, vis: 'team', output: 'Laporan PDF', approved: 'QA Manajer'),
    row('2', 'Rapat koordinasi', now, start: '10:00', end: '11:00', mins: 60, vis: 'all', type: 'Non-rutin'),
    row('3', 'Kunjungan klien', yesterday, start: '08:30', end: '12:00', mins: 210, loc: 'Client', shift: 'shift'),
    row('4', 'Test activity', older, start: '09:00', end: '09:06', mins: 6),
  ];
  final team = [
    row('5', 'Review pull request modul cuti', now, who: 'Haykal Alvito Wibowo', vis: 'team'),
    row('6', 'Deploy backend', yesterday, who: 'Rakhman Hidayat', vis: 'all', loc: 'Site'),
  ];

  Map<String, Object? Function(RequestOptions)> routesMap() => {
        '/me/timesheets': (o) {
          final q = o.queryParameters;
          if (q['from'] != null) return page(mine.where((r) => r['workDate'] == _iso(now)).toList());
          return page(mine);
        },
        '/me/timesheets/team': (_) => page(team),
        '/me/timesheets/shared': (_) => page([team[1]]),
        '/me/timesheets/options': (_) => {
              'statusCode': 200,
              'data': {
                'workLocations': ['Office', 'Client', 'Site', 'Other', 'Remote'],
                'workTypes': ['Rutin', 'Non-rutin'],
                'approverSuggestions': [
                  {'employeeId': 'm', 'name': 'QA Manajer'},
                  {'employeeId': 'h', 'name': 'Budi Santoso'}
                ],
              },
            },
        '/me/timesheets/dashboard': (_) => {
              'statusCode': 200,
              'data': {
                'year': now.year,
                'summary': {
                  'previous': List.filled(12, 0),
                  'current': [0, 8, 41, 63, 22, 18, 30, 52, 77, 80, 31, 0],
                },
                'mine': {
                  'previous': [0, 0, 0, 3, 2, 0, 0, 0, 4, 6, 0, 0],
                  'current': [0, 5, 35, 111, 29, 16, 42, 78, 111, 116, 51, 0],
                },
                'department': {
                  'previous': List.filled(12, 0),
                  'current': [0, 20, 230, 330, 175, 190, 270, 265, 280, 405, 220, 0],
                },
                'team': [
                  {'employeeId': 'a', 'name': 'Agil Satria', 'previous': 0, 'current': 590},
                  {'employeeId': 'b', 'name': 'Fajar Riza Fauzi', 'previous': 0, 'current': 310},
                  {'employeeId': 'c', 'name': 'Haykal Alvito Wibowo', 'previous': 0, 'current': 80},
                  {'employeeId': 'd', 'name': 'Rakhman Hidayat', 'previous': 0, 'current': 815},
                ],
              },
            },
      };

  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  // Screenshot hanya kalau SHOTS_DIR diisi: untuk dilihat manusia, bukan syarat lulus.
  Future<void> shot(WidgetTester tester, String name) async {
    final dir = Platform.environment['SHOTS_DIR'];
    if (dir == null) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Widget app(Widget child, Brightness b) => wrapApp(child, brightness: b);

  for (final b in [Brightness.light, Brightness.dark]) {
    final tag = b == Brightness.light ? 'light' : 'dark';

    testWidgets('hub: Saya, Tim, Bersama, Statistik ($tag)', (tester) async {
      useSmallPhone(tester);
      await installFakeApi(routes(routesMap()));

      final errors = await layoutErrors(() async {
        await tester.pumpWidget(app(const TimesheetPage(), b));
        await tester.pumpAndSettle();

        expect(find.text('HARI INI'), findsOneWidget);
        expect(find.text('3 jam 30 mnt'), findsOneWidget); // 150 + 60 menit hari ini
        expect(find.text('Rapat koordinasi'), findsOneWidget);
        await shot(tester, '1-saya-$tag');

        await tester.tap(find.text('Tim'));
        await tester.pumpAndSettle();
        expect(find.text('Review pull request modul cuti'), findsOneWidget);
        expect(find.text('Haykal Alvito Wibowo · Teknologi Informasi'), findsOneWidget);
        await shot(tester, '2-tim-$tag');

        await tester.tap(find.text('Bersama'));
        await tester.pumpAndSettle();
        expect(find.text('Deploy backend'), findsOneWidget);
        expect(find.text('Review pull request modul cuti'), findsNothing);

        await tester.tap(find.text('Statistik'));
        await tester.pumpAndSettle();
        expect(find.text('Aktivitas per bulan'), findsOneWidget);
        await shot(tester, '3-statistik-$tag');

        await tester.tap(find.text('Departemen'));
        await tester.pumpAndSettle();
        expect(find.text('Anggota tim'), findsOneWidget);
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pumpAndSettle();
        await shot(tester, '4-statistik-dept-$tag');
      });
      expect(errors, isEmpty);
    });

    testWidgets('formulir catat ($tag)', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 1900 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await installFakeApi(routes(routesMap()));

      final errors = await layoutErrors(() async {
        await tester.pumpWidget(app(TimesheetFormPage(readLocation: _noGps), b));
        await tester.pumpAndSettle();
        expect(find.text('Simpan aktivitas'), findsOneWidget);
        // Bawaan langsung valid: jam selesai setelah jam mulai.
        expect(find.textContaining('Durasi'), findsOneWidget);
        await shot(tester, '5-form-$tag');

        await tester.tap(find.text('Tambah aktivitas lain'));
        await tester.pumpAndSettle();
        expect(find.text('Simpan 2 aktivitas'), findsOneWidget);
      });
      expect(errors, isEmpty);
    });
  }

  testWidgets('formulir menolak judul kosong dan tidak memanggil server', (tester) async {
    useSmallPhone(tester);
    final api = await installFakeApi(routes(routesMap()));
    await tester.pumpWidget(app(TimesheetFormPage(readLocation: _noGps), Brightness.light));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan aktivitas'));
    await tester.pumpAndSettle();
    expect(find.text('Isi dulu apa yang dikerjakan.'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('layar kecil dengan teks besar tidak overflow', (tester) async {
    useSmallPhone(tester, textScale: 1.4);
    await installFakeApi(routes(routesMap()));
    final errors = await layoutErrors(() async {
      await tester.pumpWidget(app(const TimesheetPage(), Brightness.light));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statistik'));
      await tester.pumpAndSettle();
    });
    expect(errors, isEmpty);
  });
}
