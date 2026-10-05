class AttendanceHistoryResponseModel {
  int? statusCode;
  String? message;
  List<AttendanceHistoryData>? data;

  AttendanceHistoryResponseModel({this.statusCode, this.message, this.data});

  AttendanceHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <AttendanceHistoryData>[];
      json['data'].forEach((v) {
        data!.add(AttendanceHistoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AttendanceHistoryData {
  String? employeeShiftId;
  String? employeeId;
  String? employeeNumber;
  String? employeeName;
  String? companyName;
  String? workDate;
  String? shiftCode;
  String? shiftName;
  String? scheduledStart;
  String? scheduledEnd;
  int? lateToleranceMinutes;
  int? utcOffsetMinutes;
  Office? office;
  String? clockInAt;
  double? clockInLatitude;
  double? clockInLongitude;
  int? clockInAccuracy;
  int? clockInDistanceMeters;
  bool? clockInIsMocked;
  String? clockOutAt;
  double? clockOutLatitude;
  double? clockOutLongitude;
  int? clockOutAccuracy;
  int? clockOutDistanceMeters;
  bool? clockOutIsMocked;


  int? lateMinutes;

  bool? needsReview;
  String? reviewReason;

  String? source;

  String? deviceId;
  String? deviceReportedAt;

  String? status;

  
  String? leaveTypeName;

  AttendanceHistoryData({
    this.employeeShiftId,
    this.employeeId,
    this.employeeNumber,
    this.employeeName,
    this.companyName,
    this.workDate,
    this.shiftCode,
    this.shiftName,
    this.scheduledStart,
    this.scheduledEnd,
    this.lateToleranceMinutes,
    this.utcOffsetMinutes,
    this.office,
    this.clockInAt,
    this.clockInLatitude,
    this.clockInLongitude,
    this.clockInAccuracy,
    this.clockInDistanceMeters,
    this.clockInIsMocked,
    this.clockOutAt,
    this.clockOutLatitude,
    this.clockOutLongitude,
    this.clockOutAccuracy,
    this.clockOutDistanceMeters,
    this.clockOutIsMocked,
    this.lateMinutes,
    this.needsReview,
    this.reviewReason,
    this.source,
    this.deviceId,
    this.deviceReportedAt,
    this.status,
    this.leaveTypeName,
  });

  AttendanceHistoryData.fromJson(Map<String, dynamic> json) {
    employeeShiftId = json['employeeShiftId'];
    employeeId = json['employeeId'];
    employeeNumber = json['employeeNumber'];
    employeeName = json['employeeName'];
    companyName = json['companyName'];
    workDate = json['workDate'];
    shiftCode = json['shiftCode'];
    shiftName = json['shiftName'];
    scheduledStart = json['scheduledStart'];
    scheduledEnd = json['scheduledEnd'];
    lateToleranceMinutes = json['lateToleranceMinutes'];
    utcOffsetMinutes = json['utcOffsetMinutes'];
    office = json['office'] != null ? Office.fromJson(json['office']) : null;
    clockInAt = json['clockInAt'];
    clockInLatitude = _toDouble(json['clockInLatitude']);
    clockInLongitude = _toDouble(json['clockInLongitude']);
    clockInAccuracy = json['clockInAccuracy'];
    clockInDistanceMeters = json['clockInDistanceMeters'];
    clockInIsMocked = json['clockInIsMocked'];
    clockOutAt = json['clockOutAt'];
    clockOutLatitude = _toDouble(json['clockOutLatitude']);
    clockOutLongitude = _toDouble(json['clockOutLongitude']);
    clockOutAccuracy = json['clockOutAccuracy'];
    clockOutDistanceMeters = json['clockOutDistanceMeters'];
    clockOutIsMocked = json['clockOutIsMocked'];
    lateMinutes = json['lateMinutes'];
    needsReview = json['needsReview'];
    reviewReason = json['reviewReason'];
    source = json['source'];
    deviceId = json['deviceId'];
    deviceReportedAt = json['deviceReportedAt'];
    status = json['status'];
    leaveTypeName = json['leaveTypeName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['employeeShiftId'] = employeeShiftId;
    data['employeeId'] = employeeId;
    data['employeeNumber'] = employeeNumber;
    data['employeeName'] = employeeName;
    data['companyName'] = companyName;
    data['workDate'] = workDate;
    data['shiftCode'] = shiftCode;
    data['shiftName'] = shiftName;
    data['scheduledStart'] = scheduledStart;
    data['scheduledEnd'] = scheduledEnd;
    data['lateToleranceMinutes'] = lateToleranceMinutes;
    data['utcOffsetMinutes'] = utcOffsetMinutes;
    if (office != null) {
      data['office'] = office!.toJson();
    }
    data['clockInAt'] = clockInAt;
    data['clockInLatitude'] = clockInLatitude;
    data['clockInLongitude'] = clockInLongitude;
    data['clockInAccuracy'] = clockInAccuracy;
    data['clockInDistanceMeters'] = clockInDistanceMeters;
    data['clockInIsMocked'] = clockInIsMocked;
    data['clockOutAt'] = clockOutAt;
    data['clockOutLatitude'] = clockOutLatitude;
    data['clockOutLongitude'] = clockOutLongitude;
    data['clockOutAccuracy'] = clockOutAccuracy;
    data['clockOutDistanceMeters'] = clockOutDistanceMeters;
    data['clockOutIsMocked'] = clockOutIsMocked;
    data['lateMinutes'] = lateMinutes;
    data['needsReview'] = needsReview;
    data['reviewReason'] = reviewReason;
    data['source'] = source;
    data['deviceId'] = deviceId;
    data['deviceReportedAt'] = deviceReportedAt;
    data['status'] = status;
    data['leaveTypeName'] = leaveTypeName;
    return data;
  }
}

class Office {
  String? id;
  String? name;
  double? latitude;
  double? longitude;
  int? radiusMeters;

  Office({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  Office.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    latitude = _toDouble(json['latitude']);
    longitude = _toDouble(json['longitude']);
    radiusMeters = json['radiusMeters'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['radiusMeters'] = radiusMeters;
    return data;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}


class HistorySummary {
  final int scheduledDays;
  final int presentDays;
  final int lateDays;
  final int totalLateMinutes;
  final int incompleteDays;
  final int absentDays;
  final int leaveDays;

  const HistorySummary({
    this.scheduledDays = 0,
    this.presentDays = 0,
    this.lateDays = 0,
    this.totalLateMinutes = 0,
    this.incompleteDays = 0,
    this.absentDays = 0,
    this.leaveDays = 0,
  });

  factory HistorySummary.from(List<AttendanceHistoryData> rows) {
    var present = 0;
    var late = 0;
    var lateMinutes = 0;
    var incomplete = 0;
    var absent = 0;
    var leave = 0;

    for (final row in rows) {
      switch (row.status) {

        case 'present':
        case 'late':
          present += 1;
          break;
        case 'incomplete':
          incomplete += 1;
          break;
        case 'absent':
          absent += 1;
          break;
        case 'on_leave':
          leave += 1;
          break;
      }

      final minutes = row.lateMinutes ?? 0;
      if (minutes > 0) {
        late += 1;
        lateMinutes += minutes;
      }
    }

    return HistorySummary(
      scheduledDays: rows.length,
      presentDays: present,
      lateDays: late,
      totalLateMinutes: lateMinutes,
      incompleteDays: incomplete,
      absentDays: absent,
      leaveDays: leave,
    );
  }
}