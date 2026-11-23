import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/timesheet/model/timesheet_model.dart';

void main() {
  test('TimesheetDraft.toJson menghasilkan payload yang diterima backend', () {
    final d = TimesheetDraft(workLocation: 'Office', workType: 'Rutin')
      ..title = '  Rapat  '
      ..date = DateTime(2026, 11, 3)
      ..startMinutes = 9 * 60
      ..endMinutes = 10 * 60 + 5
      ..visibility = 'team';
    final j = d.toJson(lat: -6.2, lng: 106.8);
    expect(j['title'], 'Rapat');
    expect(j['workDate'], '2026-11-03');
    expect(j['startTime'], '09:00');
    expect(j['endTime'], '10:05');
    expect(j['visibility'], 'team');
    expect(j['latitude'], -6.2);
    expect(j.containsKey('output'), isFalse);
    expect(j.containsKey('approvedBy'), isFalse);
    expect(d.toJson().containsKey('latitude'), isFalse);
  });

  test('TimesheetPageData membaca amplop daftar + meta', () {
    final p = TimesheetPageData.fromJson({
      'data': [
        {
          'id': 'a',
          'employeeName': 'Budi',
          'title': 'Kerja',
          'workDate': '2026-11-03',
          'startTime': '09:00',
          'endTime': '10:00',
          'durationMinutes': 60,
          'shiftMode': 'non_shift',
          'workLocation': 'Office',
          'workType': 'Rutin',
          'visibility': 'all',
        }
      ],
      'meta': {'page': 1, 'limit': 30, 'total': 1, 'totalPages': 1},
    });
    expect(p.rows.single.durationMinutes, 60);
    expect(p.total, 1);
  });

  test('TimesheetDraft.from membaca jam HH:mm', () {
    final a = TimesheetPageData.fromJson({
      'data': [
        {
          'id': 'a',
          'title': 'X',
          'workDate': '2026-11-03',
          'startTime': '08:30',
          'endTime': '17:45',
          'durationMinutes': 555,
          'workLocation': 'Site',
          'workType': 'Rutin',
        }
      ],
      'meta': {},
    }).rows.single;
    final d = TimesheetDraft.from(a);
    expect(d.startMinutes, 8 * 60 + 30);
    expect(d.endMinutes, 17 * 60 + 45);
  });
}
