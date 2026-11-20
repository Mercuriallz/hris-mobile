import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/profile/model/my_profile_model.dart';

Map<String, dynamic> meJson({Object? profile = const {}}) => {
      'statusCode': 200,
      'message': 'OK',
      'data': {
        'employeeId': 'e1',
        'employeeNumber': 'EMP-001',
        'fullName': 'Budi Santoso',
        'workEmail': 'budi@kantor.id',
        'employmentStatus': 'active',
        'employmentType': 'contract',
        'joinDate': '2024-01-15',
        'contractStartDate': '2024-01-15',
        'contractEndDate': '2026-01-14',
        'jobGrade': 'III-A',
        'companyName': 'PT Maju',
        'departmentName': 'Keuangan',
        'positionTitle': 'Staf',
        'officeLocationName': 'Kantor Pusat',
        'isFlexibleLocation': true,
        'reportsToName': 'Siti',
        'photoUrl': 'https://x/p.jpg',
        'profile': profile,
      },
    };

const fullProfile = {
  'id': 'p1',
  'nationalId': '3201234567890001',
  'familyCardNumber': '3201000000000002',
  'taxId': '123456789012345',
  'birthPlace': 'Bandung',
  'dateOfBirth': '1998-03-12',
  'gender': 'male',
  'maritalStatus': 'married',
  'bloodType': 'AB',
  'religion': 'islam',
  'education': 's1',
  'motherName': 'Aminah',
  'idCardAddress': 'Jl. KTP 1',
  'personalAddress': 'Jl. Domisili 2',
  'personalEmail': 'budi@mail.id',
  'personalPhone': '0812',
  'bpjsEmploymentNumber': 12345678901,
  'bpjsHealthNumber': '0001234567890',
  'bankName': 'BCA',
  'bankAccountNumber': '1234567890',
  'bankAccountHolder': 'Budi Santoso',
  'emergencyContactName': 'Ani',
  'emergencyContactRelationship': 'Istri',
  'emergencyContactPhone': '0813',
  'createdAt': '2024-01-01T00:00:00Z',
};

void main() {
  group('MyProfileResponseModel.fromJson', () {
    test('profil lengkap', () {
      final m = MyProfileResponseModel.fromJson(meJson(profile: fullProfile));
      final d = m.data!;
      expect(m.statusCode, 200);
      expect(d.fullName, 'Budi Santoso');
      expect(d.employmentType, 'contract');
      expect(d.contractEndDate, '2026-01-14');
      expect(d.isFlexibleLocation, isTrue);
      expect(d.reportsToName, 'Siti');
      expect(d.officeLocationName, 'Kantor Pusat');
      final p = d.profile!;
      expect(p.nationalId, '3201234567890001');
      expect(p.taxId, '123456789012345');
      expect(p.bloodType, 'AB');
      expect(p.emergencyContactRelationship, 'Istri');
      // Angka dari data lama tetap jadi teks, tidak menggagalkan parsing.
      expect(p.bpjsEmploymentNumber, '12345678901');
      expect(p.bankAccountHolder, 'Budi Santoso');
    });

    test('profile null dan field kepegawaian null', () {
      final json = meJson(profile: null);
      final data = json['data'] as Map<String, dynamic>;
      for (final k in ['jobGrade', 'reportsToName', 'contractStartDate', 'contractEndDate', 'officeLocationName']) {
        data[k] = null;
      }
      data.remove('isFlexibleLocation');
      final d = MyProfileResponseModel.fromJson(json).data!;
      expect(d.profile, isNull);
      expect(d.jobGrade, isNull);
      expect(d.reportsToName, isNull);
      expect(d.isFlexibleLocation, isFalse);
      expect(d.employeeNumber, 'EMP-001');
    });

    test('profile kosong → semua field null', () {
      final p = MyProfileResponseModel.fromJson(meJson()).data!.profile!;
      expect(p.nationalId, isNull);
      expect(p.bankAccountNumber, isNull);
    });

    test('data null', () {
      expect(MyProfileResponseModel.fromJson({'statusCode': 200}).data, isNull);
    });
  });
}
