class FaceStatusResponseModel {
  int? statusCode;
  String? message;
  FaceStatusData? data;

  FaceStatusResponseModel({this.statusCode, this.message, this.data});

  FaceStatusResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? FaceStatusData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.toJson(),
      };
}

class FaceStatusData {
  bool? enrolled;
  String? enrolledAt;

  /// Versi model saat wajahnya didaftarkan.
  ///
  /// Kalau berbeda dari versi di aplikasi sekarang, wajahnya perlu didaftarkan
  /// ulang — embedding dari model berbeda tidak bisa dibandingkan.
  String? modelVersion;

  /// true berarti absensi ditolak kalau wajahnya belum terdaftar.
  bool? isRequired;

  /// false berarti verifikasi wajah belum dinyalakan di perusahaan ini, dan
  /// kamera tidak perlu dibuka saat clock in.
  bool? verificationEnabled;

  FaceStatusData({
    this.enrolled,
    this.enrolledAt,
    this.modelVersion,
    this.isRequired,
    this.verificationEnabled,
  });

  FaceStatusData.fromJson(Map<String, dynamic> json) {
    enrolled = json['enrolled'];
    enrolledAt = json['enrolledAt'];
    modelVersion = json['modelVersion'];
    // 'required' di JSON, bukan nama field Dart — 'required' kata kunci.
    isRequired = json['required'];
    verificationEnabled = json['verificationEnabled'];
  }

  Map<String, dynamic> toJson() => {
        'enrolled': enrolled,
        'enrolledAt': enrolledAt,
        'modelVersion': modelVersion,
        'required': isRequired,
        'verificationEnabled': verificationEnabled,
      };

  /// Apakah kamera perlu dibuka saat clock in.
  bool get needsVerification => verificationEnabled ?? false;

  /// Apakah wajahnya perlu didaftarkan ulang karena modelnya berganti.
  bool needsReenroll(String currentModelVersion) =>
      (enrolled ?? false) &&
      modelVersion != null &&
      modelVersion != currentModelVersion;
}