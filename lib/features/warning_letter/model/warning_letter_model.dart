/// Teguran lisan atau surat peringatan dari HR.
///
/// `status` dihitung server (aktif, berakhir, dicabut, dll.), jadi aplikasi
/// tidak perlu membandingkan tanggal sendiri — jam HP yang salah tidak akan
/// membuat surat terlihat sudah berakhir padahal belum.
class WarningLetter {
  final String id;
  final String level;
  final String letterNumber;
  final String issuedDate;
  final String expiresDate;
  final String violation;
  final String detail;
  final String status;
  final String? viewedAt;
  final String? revokedAt;
  final String? revokedReason;
  final String? evaluationResult;
  final String? evaluationNote;
  final String companyName;

  const WarningLetter({
    required this.id,
    required this.level,
    required this.letterNumber,
    required this.issuedDate,
    required this.expiresDate,
    required this.violation,
    required this.detail,
    required this.status,
    this.viewedAt,
    this.revokedAt,
    this.revokedReason,
    this.evaluationResult,
    this.evaluationNote,
    this.companyName = '',
  });

  factory WarningLetter.fromJson(Map<String, dynamic> json) => WarningLetter(
        id: json['id'] as String,
        level: json['level'] as String? ?? 'verbal',
        letterNumber: json['letterNumber'] as String? ?? '',
        issuedDate: json['issuedDate'] as String? ?? '',
        expiresDate: json['expiresDate'] as String? ?? '',
        violation: json['violation'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        viewedAt: json['viewedAt'] as String?,
        revokedAt: json['revokedAt'] as String?,
        revokedReason: json['revokedReason'] as String?,
        evaluationResult: json['evaluationResult'] as String?,
        evaluationNote: json['evaluationNote'] as String?,
        companyName: json['companyName'] as String? ?? '',
      );

  bool get isUnread => viewedAt == null;

  /// Masih berlaku: aktif, atau SP 3 yang menunggu keputusan evaluasi.
  bool get isActive => status == 'active' || status == 'evaluation_due';

  String get levelLabel => kWarningLevelLabels[level] ?? level;

  String get statusLabel => kWarningStatusLabels[status] ?? status;

  WarningLetter markViewed() => WarningLetter(
        id: id,
        level: level,
        letterNumber: letterNumber,
        issuedDate: issuedDate,
        expiresDate: expiresDate,
        violation: violation,
        detail: detail,
        status: status,
        viewedAt: viewedAt ?? DateTime.now().toIso8601String(),
        revokedAt: revokedAt,
        revokedReason: revokedReason,
        evaluationResult: evaluationResult,
        evaluationNote: evaluationNote,
        companyName: companyName,
      );
}

const kWarningLevelLabels = <String, String>{
  'verbal': 'Teguran Lisan',
  'sp1': 'SP 1',
  'sp2': 'SP 2',
  'sp3': 'SP 3',
};

const kWarningStatusLabels = <String, String>{
  'active': 'Aktif',
  'evaluation_due': 'Menunggu hasil evaluasi',
  'expired': 'Sudah berakhir',
  'revoked': 'Dicabut',
  'improved': 'Selesai',
  'terminated': 'Diberhentikan',
};
