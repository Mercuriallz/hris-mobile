/// Jenis pengajuan koreksi absensi.
///
/// Nilainya harus persis sama dengan enum AttendanceRequestType di backend —
/// `@IsEnum` akan menolak apa pun yang berbeda, termasuk beda huruf besar.
class AttendanceRequestTypes {
  static const forgotClockIn = 'forgot_clock_in';
  static const forgotClockOut = 'forgot_clock_out';
  static const wfh = 'wfh';
  static const businessTrip = 'business_trip';

  static const labels = {
    forgotClockIn: 'Lupa clock in',
    forgotClockOut: 'Lupa clock out',
    wfh: 'Kerja dari rumah',
    businessTrip: 'Dinas luar kota',
  };

  static const descriptions = {
    forgotClockIn:
        'Anda bekerja tapi tidak sempat absen masuk lewat aplikasi.',
    forgotClockOut:
        'Anda sudah absen masuk tapi lupa absen pulang.',
    wfh: 'Anda bekerja dari rumah, jadi tidak bisa absen di radius kantor.',
    businessTrip:
        'Anda bertugas di luar kota, jadi tidak bisa absen di radius kantor.',
  };
}

class CreateAttendanceRequestModel {
  final String employeeShiftId;
  final String type;

  /// Wajib untuk semua jenis KECUALI lupa clock out — di kasus itu catatan
  /// masuknya sudah ada, dan mengirim jam masuk lagi akan ditolak backend.
  final String? proposedClockInAt;

  /// Wajib untuk lupa clock out. Opsional untuk yang lain.
  final String? proposedClockOutAt;

  final String reason;

  /// Id berkas hasil unggah ke POST /me/files?category=attendance_selfie
  final String selfieFileId;

  final String? photoTakenAt;
  final double? latitude;
  final double? longitude;

  const CreateAttendanceRequestModel({
    required this.employeeShiftId,
    required this.type,
    this.proposedClockInAt,
    this.proposedClockOutAt,
    required this.reason,
    required this.selfieFileId,
    this.photoTakenAt,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "employeeShiftId": employeeShiftId,
      "type": type,
      "reason": reason.trim(),
      "selfieFileId": selfieFileId,
    };

    // Field opsional hanya disertakan kalau ada isinya. Mengirim null ke
    // @IsOptional() @IsDateString() tetap ditolak — yang diterima adalah
    // field yang tidak ada sama sekali.
    if (proposedClockInAt != null) {
      data["proposedClockInAt"] = proposedClockInAt;
    }
    if (proposedClockOutAt != null) {
      data["proposedClockOutAt"] = proposedClockOutAt;
    }
    if (photoTakenAt != null) data["photoTakenAt"] = photoTakenAt;
    if (latitude != null) data["latitude"] = latitude;
    if (longitude != null) data["longitude"] = longitude;

    return data;
  }
}