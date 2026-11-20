/// Profil dari GET /me — data kepegawaian dan data pribadi lengkap.
///
/// Dipakai dua tempat: avatar di tab Profil, dan halaman Data Diri yang
/// menampilkan seluruhnya (NIK, NPWP, rekening, BPJS) hanya-baca, sama
/// seperti portal karyawan di web.
///
/// Sengaja tidak ada `toJson`. Isinya data paling sensitif yang dimiliki
/// aplikasi ini, dan model yang tidak bisa diserialisasi tidak akan
/// "kebetulan" tersimpan ke penyimpanan lokal atau cache. Data ini cuma hidup
/// di memori dan dikosongkan saat sesi berakhir.
class MyProfileResponseModel {
  int? statusCode;
  String? message;
  MyProfileData? data;

  MyProfileResponseModel({this.statusCode, this.message, this.data});

  MyProfileResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'] is int ? json['statusCode'] : null;
    message = _str(json['message']);
    data = json['data'] is Map
        ? MyProfileData.fromJson(Map<String, dynamic>.from(json['data']))
        : null;
  }
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
  String? officeLocationName;
  bool isFlexibleLocation;
  String? reportsToName;

  /// `active` | `on_leave` | `resigned` | `terminated`.
  String? employmentStatus;

  /// `permanent` | `contract` | `probation` | `intern`.
  String? employmentType;

  /// Tanggal 'YYYY-MM-DD'.
  String? joinDate;
  String? contractStartDate;
  String? contractEndDate;

  /// Null kalau HR belum pernah mengisi data pribadi sama sekali.
  EmployeeProfileDetail? profile;

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
    this.officeLocationName,
    this.isFlexibleLocation = false,
    this.reportsToName,
    this.employmentStatus,
    this.employmentType,
    this.joinDate,
    this.contractStartDate,
    this.contractEndDate,
    this.profile,
  });

  MyProfileData.fromJson(Map<String, dynamic> json)
      : employeeId = _str(json['employeeId']),
        employeeNumber = _str(json['employeeNumber']),
        fullName = _str(json['fullName']),
        workEmail = _str(json['workEmail']),
        photoUrl = _str(json['photoUrl']),
        companyName = _str(json['companyName']),
        departmentName = _str(json['departmentName']),
        positionTitle = _str(json['positionTitle']),
        jobGrade = _str(json['jobGrade']),
        officeLocationName = _str(json['officeLocationName']),
        isFlexibleLocation = json['isFlexibleLocation'] == true,
        reportsToName = _str(json['reportsToName']),
        employmentStatus = _str(json['employmentStatus']),
        employmentType = _str(json['employmentType']),
        joinDate = _str(json['joinDate']),
        contractStartDate = _str(json['contractStartDate']),
        contractEndDate = _str(json['contractEndDate']),
        profile = json['profile'] is Map
            ? EmployeeProfileDetail.fromJson(
                Map<String, dynamic>.from(json['profile']),
              )
            : null;
}

/// Data pribadi (`profile` di GET /me). Semua field boleh null.
class EmployeeProfileDetail {
  final String? nationalId;
  final String? familyCardNumber;
  final String? taxId;
  final String? birthPlace;

  /// Tanggal 'YYYY-MM-DD'.
  final String? dateOfBirth;

  /// `male` | `female`.
  final String? gender;

  /// `single` | `married` | `divorced` | `widowed`.
  final String? maritalStatus;

  /// `A` | `B` | `AB` | `O`.
  final String? bloodType;

  /// `islam` | `protestan` | `katolik` | `hindu` | `buddha` | `konghucu` |
  /// `lainnya`.
  final String? religion;

  /// `sd` | `smp` | `sma` | `d1`..`d4` | `s1`..`s3`.
  final String? education;

  final String? motherName;
  final String? idCardAddress;
  final String? personalAddress;
  final String? personalEmail;
  final String? personalPhone;
  final String? bpjsEmploymentNumber;
  final String? bpjsHealthNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;

  const EmployeeProfileDetail({
    this.nationalId,
    this.familyCardNumber,
    this.taxId,
    this.birthPlace,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.bloodType,
    this.religion,
    this.education,
    this.motherName,
    this.idCardAddress,
    this.personalAddress,
    this.personalEmail,
    this.personalPhone,
    this.bpjsEmploymentNumber,
    this.bpjsHealthNumber,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
  });

  EmployeeProfileDetail.fromJson(Map<String, dynamic> json)
      : nationalId = _str(json['nationalId']),
        familyCardNumber = _str(json['familyCardNumber']),
        taxId = _str(json['taxId']),
        birthPlace = _str(json['birthPlace']),
        dateOfBirth = _str(json['dateOfBirth']),
        gender = _str(json['gender']),
        maritalStatus = _str(json['maritalStatus']),
        bloodType = _str(json['bloodType']),
        religion = _str(json['religion']),
        education = _str(json['education']),
        motherName = _str(json['motherName']),
        idCardAddress = _str(json['idCardAddress']),
        personalAddress = _str(json['personalAddress']),
        personalEmail = _str(json['personalEmail']),
        personalPhone = _str(json['personalPhone']),
        bpjsEmploymentNumber = _str(json['bpjsEmploymentNumber']),
        bpjsHealthNumber = _str(json['bpjsHealthNumber']),
        bankName = _str(json['bankName']),
        bankAccountNumber = _str(json['bankAccountNumber']),
        bankAccountHolder = _str(json['bankAccountHolder']),
        emergencyContactName = _str(json['emergencyContactName']),
        emergencyContactRelationship =
            _str(json['emergencyContactRelationship']),
        emergencyContactPhone = _str(json['emergencyContactPhone']);
}

/// Nilai apa pun jadi String, atau null. Nomor yang kebetulan dikirim
/// sebagai angka (mis. dari data impor lama) tidak boleh menggagalkan
/// seluruh halaman.
String? _str(Object? v) => v?.toString();
