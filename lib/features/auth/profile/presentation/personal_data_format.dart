import 'package:intl/intl.dart';

/// Format dan label untuk halaman Data Diri.
///
/// Labelnya sama dengan portal karyawan di web
/// (frontend/src/lib/employee-profile.ts dan halaman profil karyawan), supaya
/// karyawan yang membuka keduanya membaca istilah yang sama.

const kEmptyValue = '-';

/// Nilai kosong (null, atau cuma spasi) tampil "-".
String orDash(String? value) {
  final v = value?.trim() ?? '';
  return v.isEmpty ? kEmptyValue : v;
}

/// Menyamarkan nomor sensitif: 4 karakter awal dan 4 akhir terlihat, tengahnya
/// titik. "3201234567890001" → "3201 •••••••• 0001".
///
/// Pemisah (spasi, titik, strip) dibuang dulu supaya yang terlihat memang
/// karakter nomornya, bukan tanda baca NPWP.
///
/// Nomor yang terlalu pendek untuk disisakan 4+4 dengan bagian tengah yang
/// tetap tersembunyi (8 karakter atau kurang) cuma menyisakan 2 karakter
/// terakhir; dua karakter atau kurang disamarkan seluruhnya. Kosong → "-".
String maskSensitive(String? value) {
  final chars = (value ?? '').replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  if (chars.isEmpty) return kEmptyValue;

  const dot = '•';
  final n = chars.length;

  if (n <= 2) return dot * n;
  if (n <= 8) return '${dot * (n - 2)}${chars.substring(n - 2)}';

  return '${chars.substring(0, 4)} ${dot * (n - 8)} ${chars.substring(n - 4)}';
}

/// NPWP 15 digit diberi titik dan strip seperti di kartunya
/// (12.345.678.9-012.345). NPWP 16 digit (NIK) tampil apa adanya, begitu juga
/// nilai yang panjangnya tidak dikenali. Sama dengan `formatNpwp` di web.
String? formatNpwp(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final d = value.replaceAll(RegExp(r'\D'), '');
  if (d.length == 15) {
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}.'
        '${d.substring(8, 9)}-${d.substring(9, 12)}.${d.substring(12, 15)}';
  }
  if (d.length == 16) return d;
  return value;
}

final _date = DateFormat('d MMMM yyyy', 'id_ID');

/// Tanggal 'YYYY-MM-DD' → "12 Maret 1998". Kosong atau tidak terbaca → null.
String? formatProfileDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso.trim());
  return parsed == null ? null : _date.format(parsed);
}

/// Masa kerja dari tanggal bergabung. Dihitung saat dibaca, tidak disimpan —
/// angka yang disimpan benar hari ini dan salah bulan depan.
String formatTenure(String? joinDate, {DateTime? now}) {
  if (joinDate == null || joinDate.trim().isEmpty) return kEmptyValue;
  final start = DateTime.tryParse(joinDate.trim());
  if (start == null) return kEmptyValue;
  final today = now ?? DateTime.now();

  var months = (today.year - start.year) * 12 + (today.month - start.month);
  if (today.day < start.day) months -= 1;
  if (months < 0) return 'Belum mulai';

  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return '$rest bulan';
  if (rest == 0) return '$years tahun';
  return '$years tahun $rest bulan';
}

/// "1 Januari 2026 s/d 31 Desember 2026". Null kalau keduanya kosong.
String? formatContractPeriod(String? start, String? end) {
  final parts = [formatProfileDate(start), formatProfileDate(end)]
      .whereType<String>()
      .toList();
  return parts.isEmpty ? null : parts.join(' s/d ');
}

/// "Jakarta, 12 Maret 1998". Null kalau keduanya kosong.
String? formatBirth(String? place, String? dateOfBirth) {
  final parts = [
    if (place != null && place.trim().isNotEmpty) place.trim(),
    ?formatProfileDate(dateOfBirth),
  ];
  return parts.isEmpty ? null : parts.join(', ');
}

const employmentStatusLabels = {
  'active': 'Aktif',
  'on_leave': 'Cuti Panjang',
  'resigned': 'Resign',
  'terminated': 'Diberhentikan',
};

const employmentTypeLabels = {
  'permanent': 'Tetap',
  'contract': 'Kontrak',
  'probation': 'Percobaan',
  'intern': 'Magang',
};

const genderLabels = {
  'male': 'Laki-laki',
  'female': 'Perempuan',
};

const maritalStatusLabels = {
  'single': 'Belum Menikah',
  'married': 'Menikah',
  'divorced': 'Cerai Hidup',
  'widowed': 'Cerai Mati',
};

const bloodTypeLabels = {'A': 'A', 'B': 'B', 'AB': 'AB', 'O': 'O'};

const religionLabels = {
  'islam': 'Islam',
  'protestan': 'Kristen Protestan',
  'katolik': 'Katolik',
  'hindu': 'Hindu',
  'buddha': 'Buddha',
  'konghucu': 'Konghucu',
  'lainnya': 'Lainnya',
};

const educationLabels = {
  'sd': 'SD',
  'smp': 'SMP',
  'sma': 'SMA / SMK',
  'd1': 'D1',
  'd2': 'D2',
  'd3': 'D3',
  'd4': 'D4',
  's1': 'S1',
  's2': 'S2',
  's3': 'S3',
};

/// Label dari peta enum. Nilai yang belum dikenal (enum baru di backend)
/// tampil apa adanya, bukan hilang.
String? enumLabel(Map<String, String> labels, String? value) {
  if (value == null || value.isEmpty) return null;
  return labels[value] ?? value;
}
