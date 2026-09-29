

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}


class OvertimePreviewResponseModel {
  int? statusCode;
  String? message;
  OvertimePreviewData? data;

  OvertimePreviewResponseModel({this.statusCode, this.message, this.data});

  OvertimePreviewResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null
        ? OvertimePreviewData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

class OvertimePreviewData {

  String? workDate;

  double? hours;

  String? dayType;

  String? dayTypeLabel;


  String? dayTypeReason;

  List<OvertimeTier>? tiers;

  double? equivalentHours;

  String? employeeShiftId;


  double? hoursUsedToday;
  double? hoursUsedThisWeek;

  OvertimePreviewData({
    this.workDate,
    this.hours,
    this.dayType,
    this.dayTypeLabel,
    this.dayTypeReason,
    this.tiers,
    this.equivalentHours,
    this.employeeShiftId,
    this.hoursUsedToday,
    this.hoursUsedThisWeek,
  });

  OvertimePreviewData.fromJson(Map<String, dynamic> json) {
    workDate = json['workDate'];
    hours = _toDouble(json['hours']);
    dayType = json['dayType'];
    dayTypeLabel = json['dayTypeLabel'];
    dayTypeReason = json['dayTypeReason'];
    if (json['tiers'] != null) {
      tiers = <OvertimeTier>[];
      json['tiers'].forEach((v) {
        tiers!.add(OvertimeTier.fromJson(v));
      });
    }
    equivalentHours = _toDouble(json['equivalentHours']);
    employeeShiftId = json['employeeShiftId'];
    hoursUsedToday = _toDouble(json['hoursUsedToday']);
    hoursUsedThisWeek = _toDouble(json['hoursUsedThisWeek']);
  }

  Map<String, dynamic> toJson() => {
        'workDate': workDate,
        'hours': hours,
        'dayType': dayType,
        'dayTypeLabel': dayTypeLabel,
        'dayTypeReason': dayTypeReason,
        'tiers': tiers?.map((v) => v.toJson()).toList(),
        'equivalentHours': equivalentHours,
        'employeeShiftId': employeeShiftId,
        'hoursUsedToday': hoursUsedToday,
        'hoursUsedThisWeek': hoursUsedThisWeek,
      };
}


class OvertimeTier {
  double? hours;
  double? multiplier;
  String? label;
  double? equivalentHours;

  OvertimeTier({
    this.hours,
    this.multiplier,
    this.label,
    this.equivalentHours,
  });

  OvertimeTier.fromJson(Map<String, dynamic> json) {
    hours = _toDouble(json['hours']);
    multiplier = _toDouble(json['multiplier']);
    label = json['label'];
    equivalentHours = _toDouble(json['equivalentHours']);
  }

  Map<String, dynamic> toJson() => {
        'hours': hours,
        'multiplier': multiplier,
        'label': label,
        'equivalentHours': equivalentHours,
      };
}

class OvertimeRequestResponseModel {
  int? statusCode;
  String? message;
  List<OvertimeRequestData>? data;

  OvertimeRequestResponseModel({this.statusCode, this.message, this.data});

  OvertimeRequestResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <OvertimeRequestData>[];
      json['data'].forEach((v) {
        data!.add(OvertimeRequestData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.map((v) => v.toJson()).toList(),
      };
}

class OvertimeRequestData {
  String? id;
  String? workDate;
  String? startAt;
  String? endAt;
  double? hours;
  String? dayType;
  String? dayTypeReason;
  List<OvertimeTier>? tiers;
  double? equivalentHours;
  String? reason;
  String? proofFileId;
  String? createdAt;

  String? approvalStatus;

  String? decisionNote;
  String? decidedByName;

  OvertimeRequestData({
    this.id,
    this.workDate,
    this.startAt,
    this.endAt,
    this.hours,
    this.dayType,
    this.dayTypeReason,
    this.tiers,
    this.equivalentHours,
    this.reason,
    this.proofFileId,
    this.createdAt,
    this.approvalStatus,
    this.decisionNote,
    this.decidedByName,
  });

  OvertimeRequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    workDate = json['workDate'];
    startAt = json['startAt'];
    endAt = json['endAt'];
    hours = _toDouble(json['hours']);
    dayType = json['dayType'];
    dayTypeReason = json['dayTypeReason'];
    if (json['tiers'] != null) {
      tiers = <OvertimeTier>[];
      json['tiers'].forEach((v) {
        tiers!.add(OvertimeTier.fromJson(v));
      });
    }
    equivalentHours = _toDouble(json['equivalentHours']);
    reason = json['reason'];
    proofFileId = json['proofFileId'];
    createdAt = json['createdAt'];
    approvalStatus = json['approvalStatus'];
    decisionNote = json['decisionNote'];
    decidedByName = json['decidedByName'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workDate': workDate,
        'startAt': startAt,
        'endAt': endAt,
        'hours': hours,
        'dayType': dayType,
        'dayTypeReason': dayTypeReason,
        'tiers': tiers?.map((v) => v.toJson()).toList(),
        'equivalentHours': equivalentHours,
        'reason': reason,
        'proofFileId': proofFileId,
        'createdAt': createdAt,
        'approvalStatus': approvalStatus,
        'decisionNote': decisionNote,
        'decidedByName': decidedByName,
      };
}


String formatHours(double? value) {
  final hours = value ?? 0;
  if (hours == hours.roundToDouble()) return hours.toInt().toString();
  return hours.toStringAsFixed(1);
}

const Map<String, String> kDayTypeLabels = {
  'weekday': 'Hari kerja',
  'weekend': 'Akhir pekan',
  'holiday': 'Hari libur',
};