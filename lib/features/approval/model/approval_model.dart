class ApprovalResponseModel {
  int? statusCode;
  String? message;
  List<ApprovalData>? data;

  ApprovalResponseModel({this.statusCode, this.message, this.data});

  ApprovalResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ApprovalData>[];
      json['data'].forEach((v) {
        data!.add(ApprovalData.fromJson(v));
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

class ApprovalData {
  String? id;

  String? requestType;


  String? referenceId;

  String? requesterEmployeeId;


  String? summary;

  String? status;
  int? currentStep;
  String? createdAt;
  String? completedAt;

  Requester? requester;
  List<Steps>? steps;

  ApprovalData({
    this.id,
    this.requestType,
    this.referenceId,
    this.requesterEmployeeId,
    this.summary,
    this.status,
    this.currentStep,
    this.createdAt,
    this.completedAt,
    this.requester,
    this.steps,
  });

  ApprovalData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    requestType = json['requestType'];
    referenceId = json['referenceId'];
    requesterEmployeeId = json['requesterEmployeeId'];
    summary = json['summary'];
    status = json['status'];
    currentStep = json['currentStep'];
    createdAt = json['createdAt'];
    completedAt = json['completedAt'];
    requester =
        json['requester'] != null ? Requester.fromJson(json['requester']) : null;
    if (json['steps'] != null) {
      steps = <Steps>[];
      json['steps'].forEach((v) {
        steps!.add(Steps.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['requestType'] = requestType;
    data['referenceId'] = referenceId;
    data['requesterEmployeeId'] = requesterEmployeeId;
    data['summary'] = summary;
    data['status'] = status;
    data['currentStep'] = currentStep;
    data['createdAt'] = createdAt;
    data['completedAt'] = completedAt;
    if (requester != null) {
      data['requester'] = requester!.toJson();
    }
    if (steps != null) {
      data['steps'] = steps!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Requester {
  String? id;
  String? employeeNumber;
  String? fullName;

  Requester({this.id, this.employeeNumber, this.fullName});

  Requester.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    employeeNumber = json['employeeNumber'];
    fullName = json['fullName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['employeeNumber'] = employeeNumber;
    data['fullName'] = fullName;
    return data;
  }
}

class Steps {
  String? id;
  int? stepOrder;

  /// 'line_manager' atau 'hr'.
  String? approverRole;

  String? approverEmployeeId;
  String? approverNameSnapshot;
  String? status;
  String? decidedByUserId;
  String? decidedByNameSnapshot;
  String? decidedAt;
  String? note;

  Steps({
    this.id,
    this.stepOrder,
    this.approverRole,
    this.approverEmployeeId,
    this.approverNameSnapshot,
    this.status,
    this.decidedByUserId,
    this.decidedByNameSnapshot,
    this.decidedAt,
    this.note,
  });

  Steps.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    stepOrder = json['stepOrder'];
    approverRole = json['approverRole'];
    approverEmployeeId = json['approverEmployeeId'];
    approverNameSnapshot = json['approverNameSnapshot'];
    status = json['status'];
    decidedByUserId = json['decidedByUserId'];
    decidedByNameSnapshot = json['decidedByNameSnapshot'];
    decidedAt = json['decidedAt'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['stepOrder'] = stepOrder;
    data['approverRole'] = approverRole;
    data['approverEmployeeId'] = approverEmployeeId;
    data['approverNameSnapshot'] = approverNameSnapshot;
    data['status'] = status;
    data['decidedByUserId'] = decidedByUserId;
    data['decidedByNameSnapshot'] = decidedByNameSnapshot;
    data['decidedAt'] = decidedAt;
    data['note'] = note;
    return data;
  }
}

/// Label jenis pengajuan.
///
/// Dipisah dari summary karena summary sudah berisi kalimat lengkap — yang
/// dibutuhkan di kartu cuma penanda pendek untuk membedakan sekilas.
class ApprovalTypes {
  static const attendanceCorrection = 'attendance_correction';
  static const leave = 'leave';
  static const overtime = 'overtime';

  static const labels = {
    attendanceCorrection: 'Koreksi Absensi',
    leave: 'Cuti',
    overtime: 'Lembur',
  };
}