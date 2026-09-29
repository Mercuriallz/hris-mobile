
class SwapCandidate {
  String? employeeShiftId;
  String? employeeId;
  String? employeeName;
  String? employeeNumber;
  String? workDate;
  String? shiftId;
  String? shiftCode;
  String? shiftName;
  String? startAt;
  String? endAt;
  String? officeName;

  SwapCandidate({
    this.employeeShiftId,
    this.employeeId,
    this.employeeName,
    this.employeeNumber,
    this.workDate,
    this.shiftId,
    this.shiftCode,
    this.shiftName,
    this.startAt,
    this.endAt,
    this.officeName,
  });

  SwapCandidate.fromJson(Map<String, dynamic> json) {
    employeeShiftId = json['employeeShiftId'];
    employeeId = json['employeeId'];
    employeeName = json['employeeName'];
    employeeNumber = json['employeeNumber'];
    workDate = json['workDate'];
    shiftId = json['shiftId'];
    shiftCode = json['shiftCode'];
    shiftName = json['shiftName'];
    startAt = json['startAt'];
    endAt = json['endAt'];
    officeName = json['officeName'];
  }

  Map<String, dynamic> toJson() => {
        'employeeShiftId': employeeShiftId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeNumber': employeeNumber,
        'workDate': workDate,
        'shiftId': shiftId,
        'shiftCode': shiftCode,
        'shiftName': shiftName,
        'startAt': startAt,
        'endAt': endAt,
        'officeName': officeName,
      };
}

class SwapCandidateResponseModel {
  int? statusCode;
  String? message;
  List<SwapCandidate>? data;

  SwapCandidateResponseModel({this.statusCode, this.message, this.data});

  SwapCandidateResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SwapCandidate>[];
      json['data'].forEach((v) {
        data!.add(SwapCandidate.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.map((v) => v.toJson()).toList(),
      };
}

/// Satu peringatan dari pratinjau.
class SwapWarning {
  /// 'requester' atau 'counterpart' — siapa yang terkena.
  String? side;
  String? message;

  SwapWarning({this.side, this.message});

  SwapWarning.fromJson(Map<String, dynamic> json) {
    side = json['side'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() => {'side': side, 'message': message};
}

class SwapPreviewData {
  String? swapType;
  SwapCandidate? requester;
  SwapCandidate? counterpart;

  /// Kosong berarti boleh dikirim.
  List<String>? blockers;

  /// Tidak menghalangi, tapi harus dilihat sebelum mengirim.
  List<SwapWarning>? warnings;

  SwapPreviewData({
    this.swapType,
    this.requester,
    this.counterpart,
    this.blockers,
    this.warnings,
  });

  SwapPreviewData.fromJson(Map<String, dynamic> json) {
    swapType = json['swapType'];
    requester = json['requester'] != null
        ? SwapCandidate.fromJson(json['requester'])
        : null;
    counterpart = json['counterpart'] != null
        ? SwapCandidate.fromJson(json['counterpart'])
        : null;
    blockers = json['blockers'] != null
        ? List<String>.from(json['blockers'])
        : <String>[];
    if (json['warnings'] != null) {
      warnings = <SwapWarning>[];
      json['warnings'].forEach((v) {
        warnings!.add(SwapWarning.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'swapType': swapType,
        'requester': requester?.toJson(),
        'counterpart': counterpart?.toJson(),
        'blockers': blockers,
        'warnings': warnings?.map((v) => v.toJson()).toList(),
      };

  bool get canSubmit => (blockers ?? []).isEmpty;
}

class SwapPreviewResponseModel {
  int? statusCode;
  String? message;
  SwapPreviewData? data;

  SwapPreviewResponseModel({this.statusCode, this.message, this.data});

  SwapPreviewResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null
        ? SwapPreviewData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

/// Satu baris di riwayat tukar.
class SwapRequestData {
  String? id;
  String? swapType;

  /// true kalau saya yang mengajukan, false kalau saya yang diajak.
  bool? isRequester;

  String? requesterName;
  String? counterpartName;
  String? requesterWorkDate;
  String? requesterShiftName;
  String? counterpartWorkDate;
  String? counterpartShiftName;

  String? reason;
  List<SwapWarning>? warnings;

  String? approvalStatus;
  String? decisionNote;
  String? decidedByName;

  String? appliedAt;
  String? createdAt;

  SwapRequestData({
    this.id,
    this.swapType,
    this.isRequester,
    this.requesterName,
    this.counterpartName,
    this.requesterWorkDate,
    this.requesterShiftName,
    this.counterpartWorkDate,
    this.counterpartShiftName,
    this.reason,
    this.warnings,
    this.approvalStatus,
    this.decisionNote,
    this.decidedByName,
    this.appliedAt,
    this.createdAt,
  });

  SwapRequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    swapType = json['swapType'];
    isRequester = json['isRequester'];
    requesterName = json['requesterName'];
    counterpartName = json['counterpartName'];
    requesterWorkDate = json['requesterWorkDate'];
    requesterShiftName = json['requesterShiftName'];
    counterpartWorkDate = json['counterpartWorkDate'];
    counterpartShiftName = json['counterpartShiftName'];
    reason = json['reason'];
    if (json['warnings'] != null) {
      warnings = <SwapWarning>[];
      json['warnings'].forEach((v) {
        warnings!.add(SwapWarning.fromJson(v));
      });
    }
    approvalStatus = json['approvalStatus'];
    decisionNote = json['decisionNote'];
    decidedByName = json['decidedByName'];
    appliedAt = json['appliedAt'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'swapType': swapType,
        'isRequester': isRequester,
        'requesterName': requesterName,
        'counterpartName': counterpartName,
        'requesterWorkDate': requesterWorkDate,
        'requesterShiftName': requesterShiftName,
        'counterpartWorkDate': counterpartWorkDate,
        'counterpartShiftName': counterpartShiftName,
        'reason': reason,
        'warnings': warnings?.map((v) => v.toJson()).toList(),
        'approvalStatus': approvalStatus,
        'decisionNote': decisionNote,
        'decidedByName': decidedByName,
        'appliedAt': appliedAt,
        'createdAt': createdAt,
      };

  /// Nama lawan tukarnya, dari sudut pandang saya.
  ///
  /// Kartu yang selalu menyebut "pengaju" dan "rekan" memaksa orang
  /// mengingat dia yang mana. Yang berguna: siapa LAWANNYA.
  String get otherName =>
      (isRequester ?? true) ? (counterpartName ?? '-') : (requesterName ?? '-');
}

class SwapRequestResponseModel {
  int? statusCode;
  String? message;
  List<SwapRequestData>? data;

  SwapRequestResponseModel({this.statusCode, this.message, this.data});

  SwapRequestResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SwapRequestData>[];
      json['data'].forEach((v) {
        data!.add(SwapRequestData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.map((v) => v.toJson()).toList(),
      };
}