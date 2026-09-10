/// Detail pengajuan dalam bentuk siap tampil.
///
/// Backend yang menyusun judul, daftar keterangan, catatan, dan tautan
/// buktinya. Aplikasi tidak tahu apa pun tentang absensi, cuti, maupun lembur
/// — dia cuma merender apa yang dikirim.
///
/// Akibatnya begitu cuti dan lembur masuk ke aplikasi, halaman detailnya sudah
/// jalan tanpa satu baris pun berubah di sini.
class ApprovalDetailResponseModel {
  int? statusCode;
  String? message;
  DetailData? data;

  ApprovalDetailResponseModel({this.statusCode, this.message, this.data});

  ApprovalDetailResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? DetailData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class DetailData {
  ApprovalSummary? approval;
  ApprovalDetail? detail;

  DetailData({this.approval, this.detail});

  DetailData.fromJson(Map<String, dynamic> json) {
    approval = json['approval'] != null
        ? ApprovalSummary.fromJson(json['approval'])
        : null;
    detail =
        json['detail'] != null ? ApprovalDetail.fromJson(json['detail']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (approval != null) data['approval'] = approval!.toJson();
    if (detail != null) data['detail'] = detail!.toJson();
    return data;
  }
}

class ApprovalSummary {
  String? id;
  String? requestType;
  String? summary;
  String? status;
  int? currentStep;
  String? createdAt;
  DetailRequester? requester;
  List<DetailStep>? steps;

  ApprovalSummary({
    this.id,
    this.requestType,
    this.summary,
    this.status,
    this.currentStep,
    this.createdAt,
    this.requester,
    this.steps,
  });

  ApprovalSummary.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    requestType = json['requestType'];
    summary = json['summary'];
    status = json['status'];
    currentStep = json['currentStep'];
    createdAt = json['createdAt'];
    requester = json['requester'] != null
        ? DetailRequester.fromJson(json['requester'])
        : null;
    if (json['steps'] != null) {
      steps = <DetailStep>[];
      json['steps'].forEach((v) {
        steps!.add(DetailStep.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['requestType'] = requestType;
    data['summary'] = summary;
    data['status'] = status;
    data['currentStep'] = currentStep;
    data['createdAt'] = createdAt;
    if (requester != null) data['requester'] = requester!.toJson();
    if (steps != null) {
      data['steps'] = steps!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DetailRequester {
  String? id;
  String? employeeNumber;
  String? fullName;

  DetailRequester({this.id, this.employeeNumber, this.fullName});

  DetailRequester.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    employeeNumber = json['employeeNumber'];
    fullName = json['fullName'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeNumber': employeeNumber,
        'fullName': fullName,
      };
}

class DetailStep {
  String? id;
  int? stepOrder;
  String? approverRole;
  String? approverNameSnapshot;
  String? status;
  String? decidedByNameSnapshot;
  String? decidedAt;
  String? note;

  DetailStep({
    this.id,
    this.stepOrder,
    this.approverRole,
    this.approverNameSnapshot,
    this.status,
    this.decidedByNameSnapshot,
    this.decidedAt,
    this.note,
  });

  DetailStep.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    stepOrder = json['stepOrder'];
    approverRole = json['approverRole'];
    approverNameSnapshot = json['approverNameSnapshot'];
    status = json['status'];
    decidedByNameSnapshot = json['decidedByNameSnapshot'];
    decidedAt = json['decidedAt'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stepOrder': stepOrder,
        'approverRole': approverRole,
        'approverNameSnapshot': approverNameSnapshot,
        'status': status,
        'decidedByNameSnapshot': decidedByNameSnapshot,
        'decidedAt': decidedAt,
        'note': note,
      };
}

class ApprovalDetail {
  String? title;
  List<DetailField>? fields;
  String? note;

  /// Tautan bertanda tangan, berumur sepuluh menit. Diambil ulang setiap kali
  /// halaman dibuka — menyimpannya tidak ada gunanya karena akan kedaluwarsa.
  String? photoUrl;

  String? photoLabel;

  ApprovalDetail({
    this.title,
    this.fields,
    this.note,
    this.photoUrl,
    this.photoLabel,
  });

  ApprovalDetail.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    if (json['fields'] != null) {
      fields = <DetailField>[];
      json['fields'].forEach((v) {
        fields!.add(DetailField.fromJson(v));
      });
    }
    note = json['note'];
    photoUrl = json['photoUrl'];
    photoLabel = json['photoLabel'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    if (fields != null) {
      data['fields'] = fields!.map((v) => v.toJson()).toList();
    }
    data['note'] = note;
    data['photoUrl'] = photoUrl;
    data['photoLabel'] = photoLabel;
    return data;
  }
}

class DetailField {
  String? label;
  String? value;

  DetailField({this.label, this.value});

  DetailField.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}