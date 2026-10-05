
class SummaryResponseModel {
  int? statusCode;
  String? message;
  SummaryData? data;

  SummaryResponseModel({this.statusCode, this.message, this.data});

  SummaryResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? SummaryData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

class SummaryData {
  String? month;

  SummaryAttendance? attendance;
  SummaryPending? pendingRequests;
  List<UpcomingShift>? upcomingShifts;

  SummaryData({
    this.month,
    this.attendance,
    this.pendingRequests,
    this.upcomingShifts,
  });

  SummaryData.fromJson(Map<String, dynamic> json) {
    month = json['month'];
    attendance = json['attendance'] != null
        ? SummaryAttendance.fromJson(json['attendance'])
        : null;
    pendingRequests = json['pendingRequests'] != null
        ? SummaryPending.fromJson(json['pendingRequests'])
        : null;
    if (json['upcomingShifts'] != null) {
      upcomingShifts = <UpcomingShift>[];
      json['upcomingShifts'].forEach((v) {
        upcomingShifts!.add(UpcomingShift.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'attendance': attendance?.toJson(),
        'pendingRequests': pendingRequests?.toJson(),
        'upcomingShifts': upcomingShifts?.map((v) => v.toJson()).toList(),
      };
}

class SummaryAttendance {
  int? scheduledDays;
  int? presentDays;
  int? lateDays;
  int? totalLateMinutes;
  int? incompleteDays;
  int? absentDays;
  int? leaveDays;

  SummaryAttendance({
    this.scheduledDays,
    this.presentDays,
    this.lateDays,
    this.totalLateMinutes,
    this.incompleteDays,
    this.absentDays,
    this.leaveDays,
  });

  SummaryAttendance.fromJson(Map<String, dynamic> json) {
    scheduledDays = json['scheduledDays'];
    presentDays = json['presentDays'];
    lateDays = json['lateDays'];
    totalLateMinutes = json['totalLateMinutes'];
    incompleteDays = json['incompleteDays'];
    absentDays = json['absentDays'];
    leaveDays = json['leaveDays'];
  }

  Map<String, dynamic> toJson() => {
        'scheduledDays': scheduledDays,
        'presentDays': presentDays,
        'lateDays': lateDays,
        'totalLateMinutes': totalLateMinutes,
        'incompleteDays': incompleteDays,
        'absentDays': absentDays,
        'leaveDays': leaveDays,
      };

  bool get isEmpty => (scheduledDays ?? 0) == 0;
}

class SummaryPending {
  int? total;
  List<PendingByType>? byType;

  int? oldestDays;

  SummaryPending({this.total, this.byType, this.oldestDays});

  SummaryPending.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    if (json['byType'] != null) {
      byType = <PendingByType>[];
      json['byType'].forEach((v) {
        byType!.add(PendingByType.fromJson(v));
      });
    }
    oldestDays = json['oldestDays'];
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'byType': byType?.map((v) => v.toJson()).toList(),
        'oldestDays': oldestDays,
      };
}

class PendingByType {
  String? requestType;
  int? count;

  PendingByType({this.requestType, this.count});

  PendingByType.fromJson(Map<String, dynamic> json) {
    requestType = json['requestType'];
    count = json['count'];
  }

  Map<String, dynamic> toJson() => {
        'requestType': requestType,
        'count': count,
      };
}

class UpcomingShift {
  String? workDate;
  String? shiftName;
  String? shiftCode;
  String? startAt;
  String? endAt;

  UpcomingShift({
    this.workDate,
    this.shiftName,
    this.shiftCode,
    this.startAt,
    this.endAt,
  });

  UpcomingShift.fromJson(Map<String, dynamic> json) {
    workDate = json['workDate'];
    shiftName = json['shiftName'];
    shiftCode = json['shiftCode'];
    startAt = json['startAt'];
    endAt = json['endAt'];
  }

  Map<String, dynamic> toJson() => {
        'workDate': workDate,
        'shiftName': shiftName,
        'shiftCode': shiftCode,
        'startAt': startAt,
        'endAt': endAt,
      };
}

/// Label jenis pengajuan.
const Map<String, String> kRequestTypeLabels = {
  'attendance_correction': 'Koreksi Absensi',
  'leave': 'Cuti',
  'overtime': 'Lembur',
};