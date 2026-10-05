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


  String? modelVersion;

  bool? isRequired;


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

  bool get needsVerification => verificationEnabled ?? false;

  bool needsReenroll(String currentModelVersion) =>
      (enrolled ?? false) &&
      modelVersion != null &&
      modelVersion != currentModelVersion;
}