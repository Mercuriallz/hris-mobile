class ShiftCardResponseModel {
  int? statusCode;
  String? message;
  List<ShiftCard>? data;

  ShiftCardResponseModel({this.statusCode, this.message, this.data});

  ShiftCardResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ShiftCard>[];
      json['data'].forEach((v) {
        data!.add(ShiftCard.fromJson(v));
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

class ShiftCard {
  String? employeeShiftId;
  String? shiftName;
  String? shiftCode;

  /// Tanggal jangkar shift, bukan tanggal kalender kejadiannya. Shift malam
  /// yang melewati tengah malam tetap memakai tanggal hari mulainya.
  String? workDate;

  String? startAt;
  String? endAt;
  bool? crossesMidnight;
  Office? office;

  /// Kapan clock in paling awal diperbolehkan.
  String? clockInOpensAt;

  /// true berarti radius kantor tidak diperiksa untuk karyawan ini.
  ///
  /// Karyawan lapangan yang tidak tahu dirinya boleh absen di mana saja akan
  /// ragu menekan clock in dari lokasi pelanggan — dan keraguan itu berakhir
  /// sebagai telepon ke HR.
  bool? isFlexibleLocation;

  /// 'upcoming', 'open', 'done', 'missed', atau 'incomplete'.
  String? state;

  bool? canClockIn;
  bool? canClockOut;
  Attendance? attendance;

  ShiftCard({
    this.employeeShiftId,
    this.shiftName,
    this.shiftCode,
    this.workDate,
    this.startAt,
    this.endAt,
    this.crossesMidnight,
    this.office,
    this.clockInOpensAt,
    this.isFlexibleLocation,
    this.state,
    this.canClockIn,
    this.canClockOut,
    this.attendance,
  });

  ShiftCard.fromJson(Map<String, dynamic> json) {
    employeeShiftId = json['employeeShiftId'];
    shiftName = json['shiftName'];
    shiftCode = json['shiftCode'];
    workDate = json['workDate'];
    startAt = json['startAt'];
    endAt = json['endAt'];
    crossesMidnight = json['crossesMidnight'];
    office = json['office'] != null ? Office.fromJson(json['office']) : null;
    clockInOpensAt = json['clockInOpensAt'];
    isFlexibleLocation = json['isFlexibleLocation'];
    state = json['state'];
    canClockIn = json['canClockIn'];
    canClockOut = json['canClockOut'];
    attendance = json['attendance'] != null
        ? Attendance.fromJson(json['attendance'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['employeeShiftId'] = employeeShiftId;
    data['shiftName'] = shiftName;
    data['shiftCode'] = shiftCode;
    data['workDate'] = workDate;
    data['startAt'] = startAt;
    data['endAt'] = endAt;
    data['crossesMidnight'] = crossesMidnight;
    if (office != null) {
      data['office'] = office!.toJson();
    }
    data['clockInOpensAt'] = clockInOpensAt;
    data['isFlexibleLocation'] = isFlexibleLocation;
    data['state'] = state;
    data['canClockIn'] = canClockIn;
    data['canClockOut'] = canClockOut;
    if (attendance != null) {
      data['attendance'] = attendance!.toJson();
    }
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
    // Postgres numeric datang sebagai String lewat JSON, jadi tidak bisa
    // langsung di-cast ke double.
    latitude = json['latitude'] == null
        ? null
        : double.tryParse(json['latitude'].toString());
    longitude = json['longitude'] == null
        ? null
        : double.tryParse(json['longitude'].toString());
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

class Attendance {
  String? clockInAt;
  String? clockOutAt;
  int? lateMinutes;

  /// true kalau ada yang perlu ditinjau HR — GPS palsu terdeteksi, atau
  /// absensi tersinkron dari antrean offline.
  bool? needsReview;

  Attendance({
    this.clockInAt,
    this.clockOutAt,
    this.lateMinutes,
    this.needsReview,
  });

  Attendance.fromJson(Map<String, dynamic> json) {
    clockInAt = json['clockInAt'];
    clockOutAt = json['clockOutAt'];
    lateMinutes = json['lateMinutes'];
    needsReview = json['needsReview'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clockInAt'] = clockInAt;
    data['clockOutAt'] = clockOutAt;
    data['lateMinutes'] = lateMinutes;
    data['needsReview'] = needsReview;
    return data;
  }
}