import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:hris_mobile/features/salary_slip/model/salary_slip_model.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_widgets.dart';
import 'package:hris_mobile/features/warning_letter/presentation/warning_letter_widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('salary_slip_widgets', () {
    test('formatRupiah', () {
      expect(formatRupiah(8630000), 'Rp 8.630.000');
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(1234.5), 'Rp 1.235');
      expect(formatRupiah(-1500), '-Rp 1.500');
    });

    test('formatSlipMonth', () {
      expect(formatSlipMonth('2026-11'), 'November 2026');
      expect(formatSlipMonth('2026-01'), 'Januari 2026');
      expect(formatSlipMonth('abc'), 'abc');
      expect(formatSlipMonth(''), '');
    });

    test('formatSlipMonth bulan tidak valid tidak boleh jadi bulan lain', () {
      expect(formatSlipMonth('2026-13'), '2026-13');
    });

    test('formatSlipDate & formatSlipPeriod', () {
      expect(formatSlipDate('2026-10-01'), '1 Okt 2026');
      expect(formatSlipDate(''), '-');
      expect(formatSlipDate('rusak'), '-');
      const slip = SalarySlip(id: 'x', month: '2026-10', startDate: '2026-10-01', endDate: '2026-10-31');
      expect(formatSlipPeriod(slip), '1 Okt 2026 – 31 Okt 2026');
      const empty = SalarySlip(id: 'x', month: '', startDate: '', endDate: '');
      expect(formatSlipPeriod(empty), '- – -');
    });

    test('formatDays', () {
      expect(formatDays(22), '22');
      expect(formatDays(21.5), '21,5');
      expect(formatDays(0), '0');
    });

    test('maskAccountNumber', () {
      expect(maskAccountNumber('1234567890'), '•••• 7890');
      expect(maskAccountNumber('123 456 7890'), '•••• 7890');
      expect(maskAccountNumber(''), '-');
      expect(maskAccountNumber('   '), '-');
      expect(maskAccountNumber('1234'), '1234');
    });

    test('maskAccountNumber dengan pemisah "-" atau "." tetap menampilkan 4 digit terakhir', () {
      expect(maskAccountNumber('1234-5678-90'), '•••• 7890');
      expect(maskAccountNumber('12.345.678'), '•••• 5678');
    });
  });

  group('warning_letter_widgets', () {
    test('warningLevelColor makin pekat per tingkat, tak dikenal → abu', () {
      expect(warningLevelColor('sp1'), const Color(0xFFD97706));
      expect(warningLevelColor('sp2'), const Color(0xFFEA580C));
      expect(warningLevelColor('sp3'), const Color(0xFFDC2626));
      expect(warningLevelColor('verbal'), const Color(0xFF64748B));
      expect(warningLevelColor('???'), const Color(0xFF64748B));
    });

    test('warningStatusTone', () {
      expect(warningStatusTone('active'), StatusTone.warning);
      expect(warningStatusTone('evaluation_due'), StatusTone.danger);
      expect(warningStatusTone('terminated'), StatusTone.danger);
      expect(warningStatusTone('improved'), StatusTone.success);
      expect(warningStatusTone('expired'), StatusTone.neutral);
      expect(warningStatusTone('revoked'), StatusTone.neutral);
      expect(warningStatusTone(''), StatusTone.neutral);
    });

    test('formatLetterDate', () {
      expect(formatLetterDate('2026-11-01'), '1 Nov 2026');
      expect(formatLetterDate(''), '-');
    });

    test('formatLetterDate dengan tanggal rusak tidak boleh melempar', () {
      expect(formatLetterDate('rusak'), '-');
    });
  });
}
