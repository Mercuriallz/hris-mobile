

class LeaveBalanceResponseModel {
  int? statusCode;
  String? message;
  LeaveBalanceData? data;

  LeaveBalanceResponseModel({this.statusCode, this.message, this.data});

  LeaveBalanceResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data =
        json['data'] != null ? LeaveBalanceData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

class LeaveBalanceData {
  int? periodYear;

  /// Jatah yang terbit untuk periode ini, sudah termasuk aturan per level dan
  /// masa kerja kalau ada.
  double? entitled;

  double? used;
  double? remaining;

  /// Batas periode. Untuk basis ulang tahun kerja ini berbeda tiap karyawan —
  /// jadi tidak bisa disimpulkan dari periodYear saja.
  String? periodStart;
  String? periodEnd;

  LeaveBalanceData({
    this.periodYear,
    this.entitled,
    this.used,
    this.remaining,
    this.periodStart,
    this.periodEnd,
  });

  LeaveBalanceData.fromJson(Map<String, dynamic> json) {
    periodYear = json['periodYear'];
    entitled = _toDouble(json['entitled']);
    used = _toDouble(json['used']);
    remaining = _toDouble(json['remaining']);
    periodStart = json['periodStart'];
    periodEnd = json['periodEnd'];
  }

  Map<String, dynamic> toJson() => {
        'periodYear': periodYear,
        'entitled': entitled,
        'used': used,
        'remaining': remaining,
        'periodStart': periodStart,
        'periodEnd': periodEnd,
      };
}

// ---------------------------------------------------------------------------
// Jenis cuti
// ---------------------------------------------------------------------------

class LeaveTypeResponseModel {
  int? statusCode;
  String? message;
  List<LeaveTypeData>? data;

  LeaveTypeResponseModel({this.statusCode, this.message, this.data});

  LeaveTypeResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <LeaveTypeData>[];
      json['data'].forEach((v) {
        data!.add(LeaveTypeData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.map((v) => v.toJson()).toList(),
      };
}

class LeaveTypeData {
  String? id;
  String? code;
  String? name;

  /// 'annual', 'sick', 'special', atau 'unpaid'.
  String? category;

  bool? isPaid;

  /// false berarti jenis ini punya jatahnya sendiri dan tidak menyentuh kuota
  /// tahunan — cuti sakit dan cuti khusus begitu.
  bool? deductsQuota;

  bool? requiresAttachment;

  /// Batas per kejadian, bukan per tahun. Cuti menikah 3 hari berarti 3 hari
  /// saat menikah — bukan 3 hari setahun.
  double? maxDaysPerEvent;

  bool? isActive;

  LeaveTypeData({
    this.id,
    this.code,
    this.name,
    this.category,
    this.isPaid,
    this.deductsQuota,
    this.requiresAttachment,
    this.maxDaysPerEvent,
    this.isActive,
  });

  LeaveTypeData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    category = json['category'];
    isPaid = json['isPaid'];
    deductsQuota = json['deductsQuota'];
    requiresAttachment = json['requiresAttachment'];
    maxDaysPerEvent = _toDouble(json['maxDaysPerEvent']);
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'isPaid': isPaid,
        'deductsQuota': deductsQuota,
        'requiresAttachment': requiresAttachment,
        'maxDaysPerEvent': maxDaysPerEvent,
        'isActive': isActive,
      };
}

// ---------------------------------------------------------------------------
// Pratinjau
// ---------------------------------------------------------------------------

class LeavePreviewResponseModel {
  int? statusCode;
  String? message;
  LeavePreviewData? data;

  LeavePreviewResponseModel({this.statusCode, this.message, this.data});

  LeavePreviewResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data =
        json['data'] != null ? LeavePreviewData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

class LeavePreviewData {
  /// Hari kerja yang benar-benar terpotong — akhir pekan dan hari libur
  /// nasional sudah dikeluarkan.
  double? workingDays;

  double? paidDays;
  double? unpaidDays;

  /// Tanggal yang dilewati beserta alasannya, mis. "Hari libur nasional".
  List<LeaveSkippedDay>? skipped;

  double? balanceBefore;
  double? balanceAfter;

  LeavePreviewData({
    this.workingDays,
    this.paidDays,
    this.unpaidDays,
    this.skipped,
    this.balanceBefore,
    this.balanceAfter,
  });

  LeavePreviewData.fromJson(Map<String, dynamic> json) {
    workingDays = _toDouble(json['workingDays']);
    paidDays = _toDouble(json['paidDays']);
    unpaidDays = _toDouble(json['unpaidDays']);
    if (json['skipped'] != null) {
      skipped = <LeaveSkippedDay>[];
      json['skipped'].forEach((v) {
        skipped!.add(LeaveSkippedDay.fromJson(v));
      });
    }
    balanceBefore = _toDouble(json['balanceBefore']);
    balanceAfter = _toDouble(json['balanceAfter']);
  }

  Map<String, dynamic> toJson() => {
        'workingDays': workingDays,
        'paidDays': paidDays,
        'unpaidDays': unpaidDays,
        'skipped': skipped?.map((v) => v.toJson()).toList(),
        'balanceBefore': balanceBefore,
        'balanceAfter': balanceAfter,
      };
}

class LeaveSkippedDay {
  String? date;
  String? reason;

  LeaveSkippedDay({this.date, this.reason});

  LeaveSkippedDay.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    reason = json['reason'];
  }

  Map<String, dynamic> toJson() => {'date': date, 'reason': reason};
}

// ---------------------------------------------------------------------------
// Pengajuan
// ---------------------------------------------------------------------------

class LeaveRequestResponseModel {
  int? statusCode;
  String? message;
  List<LeaveRequestData>? data;

  LeaveRequestResponseModel({this.statusCode, this.message, this.data});

  LeaveRequestResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <LeaveRequestData>[];
      json['data'].forEach((v) {
        data!.add(LeaveRequestData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.map((v) => v.toJson()).toList(),
      };
}

class LeaveRequestData {
  String? id;
  String? leaveTypeId;
  String? startDate;
  String? endDate;
  bool? halfDay;
  double? workingDays;
  double? paidDays;
  double? unpaidDays;
  int? periodYear;
  String? reason;
  String? contactDuringLeave;
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

  /// Id lampiran yang diunggah pengaju, kalau ada.
  String? attachmentFileId;

  LeaveTypeData? leaveType;

  LeaveRequestData({
    this.id,
    this.leaveTypeId,
    this.startDate,
    this.endDate,
    this.halfDay,
    this.workingDays,
    this.paidDays,
    this.unpaidDays,
    this.periodYear,
    this.reason,
    this.contactDuringLeave,
    this.createdAt,
    this.approvalStatus,
    this.decisionNote,
    this.decidedByName,
    this.attachmentFileId,
    this.leaveType,
  });

  LeaveRequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    leaveTypeId = json['leaveTypeId'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    halfDay = json['halfDay'];
    workingDays = _toDouble(json['workingDays']);
    paidDays = _toDouble(json['paidDays']);
    unpaidDays = _toDouble(json['unpaidDays']);
    periodYear = json['periodYear'];
    reason = json['reason'];
    contactDuringLeave = json['contactDuringLeave'];
    createdAt = json['createdAt'];
    approvalStatus = json['approvalStatus'];
    decisionNote = json['decisionNote'];
    decidedByName = json['decidedByName'];
    attachmentFileId = json['attachmentFileId'];
    leaveType = json['leaveType'] != null
        ? LeaveTypeData.fromJson(json['leaveType'])
        : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leaveTypeId': leaveTypeId,
        'startDate': startDate,
        'endDate': endDate,
        'halfDay': halfDay,
        'workingDays': workingDays,
        'paidDays': paidDays,
        'unpaidDays': unpaidDays,
        'periodYear': periodYear,
        'reason': reason,
        'contactDuringLeave': contactDuringLeave,
        'createdAt': createdAt,
        'approvalStatus': approvalStatus,
        'decisionNote': decisionNote,
        'decidedByName': decidedByName,
        'attachmentFileId': attachmentFileId,
        'leaveType': leaveType?.toJson(),
      };
}

// ---------------------------------------------------------------------------
// Payload
// ---------------------------------------------------------------------------

class CreateLeaveRequestModel {
  final String leaveTypeId;
  final String startDate;
  final String endDate;
  final bool halfDay;
  final String reason;
  final String? attachmentFileId;
  final String? contactDuringLeave;

  const CreateLeaveRequestModel({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.halfDay = false,
    required this.reason,
    this.attachmentFileId,
    this.contactDuringLeave,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'leaveTypeId': leaveTypeId,
      'startDate': startDate,
      'endDate': endDate,
      'halfDay': halfDay,
      'reason': reason.trim(),
    };

    // Field opsional hanya disertakan kalau ada isinya. Mengirim null ke
    // @IsOptional() @IsUUID() tetap ditolak — yang diterima adalah field yang
    // tidak ada sama sekali.
    if (attachmentFileId != null) {
      data['attachmentFileId'] = attachmentFileId;
    }
    if (contactDuringLeave != null && contactDuringLeave!.trim().isNotEmpty) {
      data['contactDuringLeave'] = contactDuringLeave!.trim();
    }

    return data;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Label kategori untuk badge.
class LeaveCategories {
  static const labels = {
    'annual': 'Tahunan',
    'sick': 'Sakit',
    'special': 'Khusus',
    'unpaid': 'Tidak dibayar',
  };
}

/// Menampilkan jumlah hari tanpa desimal yang tidak perlu.
///
/// Cuti setengah hari menghasilkan 0.5, tapi 3 hari tidak perlu ditulis
/// "3.0" — dan angka yang selalu berdesimal membuat yang bulat terlihat
/// seperti hasil hitungan yang meragukan.
String formatDays(double? value) {
  final days = value ?? 0;
  if (days == days.roundToDouble()) return days.toInt().toString();
  return days.toStringAsFixed(1);
}