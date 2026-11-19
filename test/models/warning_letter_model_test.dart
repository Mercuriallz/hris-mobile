import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/warning_letter/model/warning_letter_model.dart';

Map<String, dynamic> letterJson([Map<String, dynamic> extra = const {}]) => {
      'id': 'wl-1',
      'level': 'sp1',
      'letterNumber': '001/SP1/X/2026',
      'issuedDate': '2026-10-01',
      'expiresDate': '2027-04-01',
      'violation': 'Terlambat berulang',
      'detail': 'Detail',
      'status': 'active',
      'viewedAt': null,
      'companyName': 'PT Contoh',
      ...extra,
    };

void main() {
  group('WarningLetter.fromJson', () {
    test('lengkap', () {
      final l = WarningLetter.fromJson(letterJson());
      expect(l.id, 'wl-1');
      expect(l.levelLabel, 'SP 1');
      expect(l.statusLabel, 'Aktif');
      expect(l.isUnread, isTrue);
      expect(l.isActive, isTrue);
    });

    test('field hilang memakai bawaan', () {
      final l = WarningLetter.fromJson({'id': 'a'});
      expect(l.level, 'verbal');
      expect(l.levelLabel, 'Teguran Lisan');
      expect(l.status, 'active');
      expect(l.issuedDate, '');
      expect(l.companyName, '');
    });

    test('level/status tak dikenal → label mentah', () {
      final l = WarningLetter.fromJson({'id': 'a', 'level': 'sp4', 'status': 'weird'});
      expect(l.levelLabel, 'sp4');
      expect(l.statusLabel, 'weird');
      expect(l.isActive, isFalse);
    });

    test('isActive untuk setiap status', () {
      const expected = {
        'active': true,
        'evaluation_due': true,
        'expired': false,
        'revoked': false,
        'improved': false,
        'terminated': false,
      };
      expected.forEach((status, active) {
        expect(WarningLetter.fromJson({'id': 'a', 'status': status}).isActive, active, reason: status);
      });
    });

    test('markViewed mengisi viewedAt sekali dan mempertahankan field lain', () {
      final l = WarningLetter.fromJson(letterJson({'revokedReason': 'r', 'evaluationNote': 'n'}));
      final v = l.markViewed();
      expect(v.isUnread, isFalse);
      expect(v.id, l.id);
      expect(v.letterNumber, l.letterNumber);
      expect(v.revokedReason, 'r');
      expect(v.evaluationNote, 'n');
      expect(v.companyName, 'PT Contoh');
      final again = WarningLetter.fromJson(letterJson({'viewedAt': '2026-01-01T00:00:00Z'})).markViewed();
      expect(again.viewedAt, '2026-01-01T00:00:00Z');
    });

    test('id numerik tidak boleh membuat parsing gagal', () {
      // Seharusnya seperti SalarySlip: json['id'].toString().
      expect(WarningLetter.fromJson(letterJson({'id': 7})).id, '7');
    });
  });
}
