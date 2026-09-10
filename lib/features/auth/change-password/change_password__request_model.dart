class ChangePasswordRequestModel {
  String? currentPassword;
  String? newPassword;

  ChangePasswordRequestModel({this.currentPassword, this.newPassword});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['currentPassword'] = currentPassword;
    data['newPassword'] = newPassword;
    return data;
  }
}
