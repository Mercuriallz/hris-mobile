import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/profile/presentation/personal_data_format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('maskSensitive', () {
    test('nomor normal: 4 awal + 4 akhir terlihat, tengah titik', () {
      expect(maskSensitive('3201234567890001'), '3201 •••••••• 0001');
      expect(maskSensitive('1234567890'), '1234 •• 7890');
      expect(maskSensitive('0001234567890'), '0001 ••••• 7890');
    });

    test('pemisah dibuang sebelum disamarkan (NPWP bertitik)', () {
      expect(maskSensitive('12.345.678.9-012.345'), '1234 ••••••• 2345');
      expect(maskSensitive(' 0123 4567 8901 '), '0123 •••• 8901');
    });

    test('nomor pendek: cuma 2 karakter terakhir terlihat', () {
      expect(maskSensitive('123456789'), '1234 • 6789');
      expect(maskSensitive('12345678'), '••••••78');
      expect(maskSensitive('12345'), '•••45');
      expect(maskSensitive('123'), '•23');
    });

    test('dua karakter atau kurang disamarkan semua', () {
      expect(maskSensitive('12'), '••');
      expect(maskSensitive('7'), '•');
    });

    test('null / kosong / cuma pemisah → "-"', () {
      expect(maskSensitive(null), '-');
      expect(maskSensitive(''), '-');
      expect(maskSensitive('   '), '-');
      expect(maskSensitive('.-.'), '-');
    });

    test('tidak pernah membocorkan bagian tengah', () {
      const nik = '3201234567890001';
      expect(maskSensitive(nik).contains('23456789'), isFalse);
    });
  });

  group('format', () {
    test('formatNpwp', () {
      expect(formatNpwp('123456789012345'), '12.345.678.9-012.345');
      expect(formatNpwp('3201234567890001'), '3201234567890001');
      expect(formatNpwp('abc'), 'abc');
      expect(formatNpwp(null), isNull);
      expect(formatNpwp(''), isNull);
    });

    test('formatProfileDate → tanggal Indonesia', () {
      expect(formatProfileDate('1998-03-12'), '12 Maret 1998');
      expect(formatProfileDate(null), isNull);
      expect(formatProfileDate('bukan tanggal'), isNull);
    });

    test('formatTenure', () {
      final now = DateTime(2026, 11, 20);
      expect(formatTenure('2020-01-15', now: now), '6 tahun 10 bulan');
      expect(formatTenure('2024-11-20', now: now), '2 tahun');
      expect(formatTenure('2026-06-21', now: now), '4 bulan');
      expect(formatTenure('2026-12-01', now: now), 'Belum mulai');
      expect(formatTenure(null, now: now), '-');
    });

    test('formatContractPeriod dan formatBirth', () {
      expect(formatContractPeriod('2026-01-01', '2026-12-31'), '1 Januari 2026 s/d 31 Desember 2026');
      expect(formatContractPeriod(null, '2026-12-31'), '31 Desember 2026');
      expect(formatContractPeriod(null, null), isNull);
      expect(formatBirth('Bandung', '1998-03-12'), 'Bandung, 12 Maret 1998');
      expect(formatBirth(null, '1998-03-12'), '12 Maret 1998');
      expect(formatBirth('  ', null), isNull);
    });

    test('enumLabel: label web, nilai tak dikenal tampil apa adanya', () {
      expect(enumLabel(religionLabels, 'protestan'), 'Kristen Protestan');
      expect(enumLabel(educationLabels, 'sma'), 'SMA / SMK');
      expect(enumLabel(maritalStatusLabels, 'widowed'), 'Cerai Mati');
      expect(enumLabel(employmentTypeLabels, 'probation'), 'Percobaan');
      expect(enumLabel(employmentStatusLabels, 'on_leave'), 'Cuti Panjang');
      expect(enumLabel(genderLabels, 'female'), 'Perempuan');
      expect(enumLabel(genderLabels, 'other'), 'other');
      expect(enumLabel(genderLabels, null), isNull);
    });
  });
}
