/// Profil dari GET /me.
///
/// Cuma memuat yang dipakai halaman Profil. Respons backend jauh lebih
/// lengkap — NIK, NPWP, nomor rekening — tapi aplikasi tidak menampilkannya,
/// jadi tidak ada gunanya memodelkan seluruhnya. Field yang dimodelkan tapi
/// tidak dipakai akan jadi milik siapa pun yang lupa bahwa dia ada.
class MyProfileResponseModel {
  int? statusCode;
  String? message;
  MyProfileData? data;

  MyProfileResponseModel({this.statusCode, this.message, this.data});

  MyProfileResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? MyProfileData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

class MyProfileData {
  String? employeeId;
  String? employeeNumber;
  String? fullName;
  String? workEmail;

  /// URL bertanda tangan, berumur satu jam.
  ///
  /// Tidak disimpan ke penyimpanan lokal: tanda tangannya kedaluwarsa, jadi
  /// URL yang disimpan hari ini akan gagal besok — dan avatarnya berubah jadi
  /// inisial tanpa sebab yang terlihat.
  String? photoUrl;

  String? companyName;
  String? departmentName;
  String? positionTitle;
  String? jobGrade;

  MyProfileData({
    this.employeeId,
    this.employeeNumber,
    this.fullName,
    this.workEmail,
    this.photoUrl,
    this.companyName,
    this.departmentName,
    this.positionTitle,
    this.jobGrade,
  });

  MyProfileData.fromJson(Map<String, dynamic> json) {
    employeeId = json['employeeId'];
    employeeNumber = json['employeeNumber'];
    fullName = json['fullName'];
    workEmail = json['workEmail'];
    photoUrl = json['photoUrl'];
    companyName = json['companyName'];
    departmentName = json['departmentName'];
    positionTitle = json['positionTitle'];
    jobGrade = json['jobGrade'];
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeNumber': employeeNumber,
        'fullName': fullName,
        'workEmail': workEmail,
        'photoUrl': photoUrl,
        'companyName': companyName,
        'departmentName': departmentName,
        'positionTitle': positionTitle,
        'jobGrade': jobGrade,
      };
}