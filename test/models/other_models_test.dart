import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/approval/model/approval_detail_model.dart';
import 'package:hris_mobile/features/approval/model/approval_model.dart';
import 'package:hris_mobile/features/attendance-history/model/attendance_history_model.dart';
import 'package:hris_mobile/features/attendance/model/summary_model.dart';
import 'package:hris_mobile/features/leave/model/leave_model.dart';
import 'package:hris_mobile/features/overtime/model/overtime_model.dart';
import 'package:hris_mobile/features/shift-swap/model/shift_swap_model.dart';

void main() {
  group('ShiftSwap models', () {
    test('SwapRequestResponseModel lengkap + otherName dari sudut pandang saya', () {
      final m = SwapRequestResponseModel.fromJson({
        'statusCode': 200,
        'message': 'ok',
        'data': [
          {'id': 'a', 'isRequester': true, 'requesterName': 'Saya', 'counterpartName': 'Rina', 'warnings': [
            {'side': 'requester', 'message': 'Jam kerja > 12'}
          ]},
          {'id': 'b', 'isRequester': false, 'requesterName': 'Doni', 'counterpartName': 'Saya'},
          {'id': 'c'},
        ],
      });
      expect(m.data, hasLength(3));
      expect(m.data![0].otherName, 'Rina');
      expect(m.data![0].warnings!.single.side, 'requester');
      expect(m.data![1].otherName, 'Doni');
      expect(m.data![2].otherName, '-');
    });

    test('data null → data null, bukan exception', () {
      expect(SwapRequestResponseModel.fromJson({'statusCode': 200}).data, isNull);
      expect(SwapCandidateResponseModel.fromJson({}).data, isNull);
    });

    test('SwapPreviewData: blockers hilang → bisa dikirim; ada blocker → tidak', () {
      expect(SwapPreviewData.fromJson({}).canSubmit, isTrue);
      expect(SwapPreviewData.fromJson({'blockers': ['Bentrok']}).canSubmit, isFalse);
      final p = SwapPreviewResponseModel.fromJson({
        'data': {
          'swapType': 'swap',
          'requester': {'employeeShiftId': 'r1'},
          'counterpart': {'employeeShiftId': 'c1', 'employeeName': 'Rina'},
          'blockers': <String>[],
          'warnings': [{'side': 'counterpart', 'message': 'm'}],
        }
      });
      expect(p.data!.counterpart!.employeeName, 'Rina');
      expect(p.data!.warnings, hasLength(1));
      expect(p.data!.canSubmit, isTrue);
    });

    test('toJson → fromJson bolak-balik', () {
      final c = SwapCandidate(employeeShiftId: 'x', employeeName: 'A', startAt: '2026-11-20T01:00:00Z');
      final back = SwapCandidate.fromJson(c.toJson());
      expect(back.employeeShiftId, 'x');
      expect(back.startAt, c.startAt);
    });
  });

  group('AttendanceHistory', () {
    test('koordinat string/int/double diurai, field hilang aman', () {
      final d = AttendanceHistoryData.fromJson({
        'employeeShiftId': 's1',
        'clockInLatitude': '-6.2',
        'clockInLongitude': 106,
        'clockOutLatitude': null,
        'office': {'id': 'o', 'latitude': '-6.2', 'longitude': 106.8, 'radiusMeters': 100},
        'lateMinutes': 5,
        'status': 'late',
      });
      expect(d.clockInLatitude, -6.2);
      expect(d.clockInLongitude, 106.0);
      expect(d.clockOutLatitude, isNull);
      expect(d.office!.latitude, -6.2);
      expect(AttendanceHistoryData.fromJson({}).status, isNull);
    });

    test('HistorySummary menghitung hadir/terlambat/tidak lengkap/absen/cuti', () {
      final rows = [
        AttendanceHistoryData(status: 'present'),
        AttendanceHistoryData(status: 'late', lateMinutes: 12),
        AttendanceHistoryData(status: 'incomplete', lateMinutes: 3),
        AttendanceHistoryData(status: 'absent'),
        AttendanceHistoryData(status: 'on_leave'),
        AttendanceHistoryData(status: 'scheduled'),
      ];
      final s = HistorySummary.from(rows);
      expect(s.scheduledDays, 6);
      expect(s.presentDays, 2);
      expect(s.lateDays, 2);
      expect(s.totalLateMinutes, 15);
      expect(s.incompleteDays, 1);
      expect(s.absentDays, 1);
      expect(s.leaveDays, 1);
    });

    test('angka bulat yang dikirim sebagai string/double tidak membuat parsing gagal', () {
      final d = AttendanceHistoryData.fromJson({'lateMinutes': '5', 'clockInAccuracy': 12.5, 'utcOffsetMinutes': 420.0});
      expect(d.lateMinutes, 5);
    });
  });

  group('Overtime', () {
    test('jam & tier string/num/null', () {
      final d = OvertimePreviewData.fromJson({
        'hours': '2.5',
        'tiers': [
          {'hours': 1, 'multiplier': '1.5', 'equivalentHours': 1.5},
          {'hours': '1.5', 'multiplier': 2},
        ],
        'equivalentHours': null,
        'hoursUsedToday': 'abc',
      });
      expect(d.hours, 2.5);
      expect(d.tiers![0].multiplier, 1.5);
      expect(d.tiers![1].hours, 1.5);
      expect(d.equivalentHours, isNull);
      expect(d.hoursUsedToday, isNull);
    });

    test('OvertimeRequestResponseModel daftar', () {
      final m = OvertimeRequestResponseModel.fromJson({
        'data': [
          {'id': 'o1', 'hours': '3', 'approvalStatus': 'pending'}
        ]
      });
      expect(m.data!.single.hours, 3);
    });

    test('formatHours', () {
      expect(formatHours(null), '0');
      expect(formatHours(2), '2');
      expect(formatHours(1.5), '1.5');
    });
  });

  group('Leave', () {
    test('saldo string/num', () {
      final b = LeaveBalanceData.fromJson({'periodYear': 2026, 'entitled': '12', 'used': 2.5, 'remaining': null});
      expect(b.entitled, 12);
      expect(b.used, 2.5);
      expect(b.remaining, isNull);
    });

    test('LeaveRequestData dengan leaveType bersarang', () {
      final r = LeaveRequestData.fromJson({
        'id': 'l1',
        'workingDays': '1.5',
        'leaveType': {'id': 't', 'name': 'Tahunan', 'maxDaysPerEvent': '3'},
      });
      expect(r.workingDays, 1.5);
      expect(r.leaveType!.maxDaysPerEvent, 3);
    });

    test('CreateLeaveRequestModel tidak mengirim field opsional kosong', () {
      final j = const CreateLeaveRequestModel(
        leaveTypeId: 't',
        startDate: '2026-11-20',
        endDate: '2026-11-21',
        reason: '  liburan  ',
        contactDuringLeave: '   ',
      ).toJson();
      expect(j.containsKey('attachmentFileId'), isFalse);
      expect(j.containsKey('contactDuringLeave'), isFalse);
      expect(j['reason'], 'liburan');
    });

    test('formatDays (cuti)', () {
      expect(formatDays(null), '0');
      expect(formatDays(3), '3');
      expect(formatDays(0.5), '0.5');
    });

    test('periodYear string tidak membuat parsing gagal', () {
      expect(LeaveBalanceData.fromJson({'periodYear': '2026'}).periodYear, 2026);
    });
  });

  group('Approval', () {
    test('daftar & detail', () {
      final m = ApprovalResponseModel.fromJson({
        'data': [
          {
            'id': 'a1',
            'currentStep': 1,
            'requester': {'fullName': 'Budi'},
            'steps': [
              {'id': 's1', 'stepOrder': 1, 'status': 'pending'}
            ]
          }
        ]
      });
      expect(m.data!.single.requester!.fullName, 'Budi');
      expect(m.data!.single.steps!.single.stepOrder, 1);

      final d = ApprovalDetailResponseModel.fromJson({
        'data': {
          'approval': {'id': 'a1', 'steps': []},
          'detail': {
            'title': 'Cuti',
            'fields': [
              {'label': 'Tanggal', 'value': '20 Nov'}
            ]
          }
        }
      });
      expect(d.data!.detail!.fields!.single.label, 'Tanggal');
      expect(ApprovalDetailResponseModel.fromJson({}).data, isNull);
    });
  });

  group('Attendance summary', () {
    test('lengkap & kosong', () {
      final s = SummaryResponseModel.fromJson({
        'data': {
          'month': '2026-11',
          'attendance': {'scheduledDays': 20, 'presentDays': 18, 'totalLateMinutes': 30},
          'pendingRequests': {
            'total': 2,
            'byType': [
              {'requestType': 'leave', 'count': 2}
            ],
            'oldestDays': null
          },
          'upcomingShifts': [
            {'workDate': '2026-11-20', 'shiftName': 'Pagi'}
          ],
        }
      });
      expect(s.data!.attendance!.isEmpty, isFalse);
      expect(s.data!.pendingRequests!.byType!.single.count, 2);
      expect(s.data!.upcomingShifts!.single.shiftName, 'Pagi');
      expect(SummaryAttendance.fromJson({}).isEmpty, isTrue);
    });
  });
}
