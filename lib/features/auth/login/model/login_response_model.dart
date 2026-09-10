class LoginResponseModel {
  int? statusCode;
  String? message;
  Data? data;

  LoginResponseModel({this.statusCode, this.message, this.data});

  LoginResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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

class Data {
  String? accessToken;

  /// 'employee', 'manager', 'hr_admin', 'owner', atau 'super_admin'.
  ///
  /// Aplikasi ini hanya untuk yang punya data kepegawaian. Owner yang mencoba
  /// login di sini ditolak di lapisan repository, bukan di sini.
  String? role;
  User? user;

  Data({this.accessToken, this.role, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'];
    role = json['role'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accessToken'] = accessToken;
    data['role'] = role;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  String? id;
  String? email;
  String? name;
  String? groupId;

  /// null berarti akun ini tidak terhubung ke data kepegawaian — dan tanpa itu
  /// tidak ada shift yang bisa diabsen.
  String? employeeId;

  /// true berarti seluruh endpoint lain akan menolak sampai passwordnya
  /// diganti. Dijaga PasswordChangeRequiredGuard di backend.
  bool? mustChangePassword;

  User({
    this.id,
    this.email,
    this.name,
    this.groupId,
    this.employeeId,
    this.mustChangePassword,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    name = json['name'];
    groupId = json['groupId'];
    employeeId = json['employeeId'];
    mustChangePassword = json['mustChangePassword'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    data['name'] = name;
    data['groupId'] = groupId;
    data['employeeId'] = employeeId;
    data['mustChangePassword'] = mustChangePassword;
    return data;
  }
}