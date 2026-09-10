class LoginRequestModel {
  final String email;
  final String password;

  /// Dikirim di SETIAP login, bukan hanya yang pertama.
  ///
  /// Backend yang memutuskan: kalau karyawan belum punya perangkat terdaftar,
  /// yang ini diikat; kalau sudah dan berbeda, login ditolak. Aplikasi tidak
  /// perlu tahu mana yang terjadi — cukup mengirim dan menampilkan pesannya.
  final String deviceId;

  /// Nama perangkat untuk ditampilkan HR di daftar perangkat.
  final String deviceModel;

  const LoginRequestModel({
    required this.email,
    required this.password,
    required this.deviceId,
    required this.deviceModel,
  });

  Map<String, dynamic> toJson() => {
        "email": email.trim().toLowerCase(),
        "password": password,
        "deviceId": deviceId,
        "deviceModel": deviceModel,
      };
}

class ChangePasswordRequestModel {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequestModel({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        "currentPassword": currentPassword,
        "newPassword": newPassword,
      };
}