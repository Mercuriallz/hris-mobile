class AttendanceRequestResponseModel {
  int? statusCode;
  String? message;
  List<AttendanceRequestData>? data;

  AttendanceRequestResponseModel({this.statusCode, this.message, this.data});

  AttendanceRequestResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <AttendanceRequestData>[];
      json['data'].forEach((v) {
        data!.add(AttendanceRequestData.fromJson(v));
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

class AttendanceRequestData {
  String? id;
  String? employeeShiftId;

  /// 'forgot_clock_in', 'forgot_clock_out', 'wfh', atau 'business_trip'.
  String? type;

  String? proposedClockInAt;
  String? proposedClockOutAt;
  String? reason;
  String? selfieFileId;
  String? photoTakenAt;
  double? latitude;
  double? longitude;
  String? createdAt;

  /// 'pending', 'approved', 'rejected', atau 'cancelled'. Diambil dari
  /// ApprovalRequest, bukan disimpan di pengajuan ini.
  String? approvalStatus;

  /// Catatan dari langkah persetujuan terakhir yang diputuskan.
  ///
  /// Untuk penolakan inilah alasannya. "Ditolak" tanpa alasan mengirim orang
  /// bertanya ke HR — dan itu persis yang ingin dihindari.
  String? decisionNote;

  String? decidedByName;

  EmployeeShift? employeeShift;

  AttendanceRequestData({
    this.id,
    this.employeeShiftId,
    this.type,
    this.proposedClockInAt,
    this.proposedClockOutAt,
    this.reason,
    this.selfieFileId,
    this.photoTakenAt,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.approvalStatus,
    this.decisionNote,
    this.decidedByName,
    this.employeeShift,
  });

  AttendanceRequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    employeeShiftId = json['employeeShiftId'];
    type = json['type'];
    proposedClockInAt = json['proposedClockInAt'];
    proposedClockOutAt = json['proposedClockOutAt'];
    reason = json['reason'];
    selfieFileId = json['selfieFileId'];
    photoTakenAt = json['photoTakenAt'];
    latitude = _toDouble(json['latitude']);
    longitude = _toDouble(json['longitude']);
    createdAt = json['createdAt'];
    approvalStatus = json['approvalStatus'];
    decisionNote = json['decisionNote'];
    decidedByName = json['decidedByName'];
    employeeShift = json['employeeShift'] != null
        ? EmployeeShift.fromJson(json['employeeShift'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['employeeShiftId'] = employeeShiftId;
    data['type'] = type;
    data['proposedClockInAt'] = proposedClockInAt;
    data['proposedClockOutAt'] = proposedClockOutAt;
    data['reason'] = reason;
    data['selfieFileId'] = selfieFileId;
    data['photoTakenAt'] = photoTakenAt;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['createdAt'] = createdAt;
    data['approvalStatus'] = approvalStatus;
    data['decisionNote'] = decisionNote;
    data['decidedByName'] = decidedByName;
    if (employeeShift != null) {
      data['employeeShift'] = employeeShift!.toJson();
    }
    return data;
  }
}

class EmployeeShift {
  String? id;
  String? workDate;
  Shift? shift;

  EmployeeShift({this.id, this.workDate, this.shift});

  EmployeeShift.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    workDate = json['workDate'];
    shift = json['shift'] != null ? Shift.fromJson(json['shift']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['workDate'] = workDate;
    if (shift != null) {
      data['shift'] = shift!.toJson();
    }
    return data;
  }
}

class Shift {
  String? id;
  String? code;
  String? name;
  String? startTime;
  String? endTime;

  Shift({this.id, this.code, this.name, this.startTime, this.endTime});

  Shift.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    startTime = json['startTime'];
    endTime = json['endTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['name'] = name;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    return data;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}