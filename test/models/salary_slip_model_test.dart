import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/model/salary_slip_model.dart';

Map<String, dynamic> slipJson([Map<String, dynamic> extra = const {}]) => {
      'id': 'slip-1',
      'month': '2026-10',
      'startDate': '2026-10-01',
      'endDate': '2026-10-31',
      'employeeName': 'Budi',
      'bankName': 'BCA',
      'bankAccountNumber': '1234567890',
      'totalWorkingDays': 22,
      'paymentDays': '21.5',
      'lwpDays': '0.5',
      'grossPay': '9000000.00',
      'totalDeduction': 370000,
      'totalEmployerContribution': null,
      'netPay': '8630000.00',
      'roundedNetPay': '8630000',
      'lines': {
        'earnings': [
          {'componentId': 1, 'name': 'Gaji Pokok', 'amount': '8000000.00'},
          {'componentId': 'c2', 'name': 'Tunjangan', 'amount': 1000000},
          {'componentId': 'c3', 'name': 'Basis BPJS', 'amount': '5000000', 'statistical': true},
        ],
        'deductions': [
          {'componentId': 'd1', 'name': 'BPJS', 'amount': 370000, 'excludedFromTotal': false},
        ],
      },
      ...extra,
    };

void main() {
  group('SalarySlip.fromJson', () {
    test('angka sebagai string/num/null diurai tanpa gagal', () {
      final s = SalarySlip.fromJson(slipJson());
      expect(s.id, 'slip-1');
      expect(s.paymentDays, 21.5);
      expect(s.lwpDays, 0.5);
      expect(s.grossPay, 9000000);
      expect(s.totalDeduction, 370000);
      expect(s.totalEmployerContribution, 0);
      expect(s.netPay, 8630000);
      expect(s.totalWorkingDays, 22);
      expect(s.earnings, hasLength(3));
      expect(s.earnings.first.componentId, '1');
      expect(s.earnings.first.amount, 8000000);
      expect(s.earnings[2].isHelper, isTrue);
      expect(s.deductions.single.isHelper, isFalse);
      expect(s.employerContributions, isEmpty);
    });

    test('field hilang memakai nilai bawaan', () {
      final s = SalarySlip.fromJson({'id': 'x'});
      expect(s.month, '');
      expect(s.startDate, '');
      expect(s.netPay, 0);
      expect(s.earnings, isEmpty);
      expect(s.bankAccountNumber, '');
    });

    test('id numerik diubah jadi string', () {
      expect(SalarySlip.fromJson({'id': 42}).id, '42');
    });

    test('lines bukan Map / berisi elemen bukan Map tidak membuat gagal', () {
      expect(SalarySlip.fromJson({'id': 'x', 'lines': []}).earnings, isEmpty);
      final s = SalarySlip.fromJson({
        'id': 'x',
        'lines': {
          'earnings': [null, 'rusak', 3, {'name': 'OK', 'amount': '1'}],
        },
      });
      expect(s.earnings.single.name, 'OK');
    });

    test('totalWorkingDays berupa string desimal dibulatkan', () {
      expect(SalarySlip.fromJson({'id': 'x', 'totalWorkingDays': '21.6'}).totalWorkingDays, 22);
    });

    test('string angka tidak valid → 0, bukan exception', () {
      final s = SalarySlip.fromJson({'id': 'x', 'netPay': 'abc', 'grossPay': ''});
      expect(s.netPay, 0);
      expect(s.grossPay, 0);
    });

    test('takeHomePay memakai roundedNetPay, jatuh ke netPay kalau 0', () {
      expect(SalarySlip.fromJson(slipJson()).takeHomePay, 8630000);
      final s = SalarySlip.fromJson(slipJson({'roundedNetPay': null, 'netPay': '8629999.5'}));
      expect(s.takeHomePay, 8629999.5);
    });

    test('field teks bertipe bukan String (mis. month numerik) — saat ini melempar', () {
      // Dokumentasi perilaku: `as String?` melempar TypeError kalau server
      // mengirim tipe lain. Backend saat ini selalu mengirim string, jadi
      // ini hanya catatan ketahanan.
      expect(() => SalarySlip.fromJson({'id': 'x', 'month': 202610}), throwsA(isA<TypeError>()));
    });
  });
}
