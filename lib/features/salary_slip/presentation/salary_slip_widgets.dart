import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../model/salary_slip_model.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _date = DateFormat('d MMM yyyy', 'id_ID');
final _monthYear = DateFormat('MMMM yyyy', 'id_ID');

/// "Rp 8.630.000". Nilai negatif tetap diberi tanda minus di depan.
String formatRupiah(double value) => _rupiah.format(value);

/// Pengganti nominal saat disembunyikan.
const kHiddenAmount = 'Rp •••••••';

/// "2026-11" → "November 2026".
String formatSlipMonth(String month) {
  final parsed = DateTime.tryParse('$month-01');
  return parsed == null ? month : _monthYear.format(parsed);
}

String formatSlipDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? '-' : _date.format(parsed);
}

String formatSlipPeriod(SalarySlip slip) =>
    '${formatSlipDate(slip.startDate)} – ${formatSlipDate(slip.endDate)}';

/// Angka hari tanpa ".0" kalau bulat: 22 → "22", 21.5 → "21,5".
String formatDays(double days) =>
    days == days.roundToDouble() ? days.toStringAsFixed(0) : days.toString().replaceAll('.', ',');

/// Hanya 4 digit terakhir yang terlihat: "•••• 7890".
String maskAccountNumber(String number) {
  final digits = number.replaceAll(RegExp(r'\s+'), '');
  if (digits.isEmpty) return '-';
  if (digits.length <= 4) return digits;
  return '•••• ${digits.substring(digits.length - 4)}';
}

/// Kartu satu slip di daftar.
class SalarySlipCard extends StatelessWidget {
  final SalarySlip slip;
  final bool showAmount;
  final VoidCallback onTap;

  const SalarySlipCard({
    super.key,
    required this.slip,
    required this.showAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatSlipMonth(slip.month), style: AppText.bodyStrong),
                    const SizedBox(height: 8),
                    Text('GAJI BERSIH', style: AppText.label),
                    const SizedBox(height: 2),
                    Text(
                      showAmount ? formatRupiah(slip.takeHomePay) : kHiddenAmount,
                      style: AppText.h1.copyWith(color: AppColor.primary),
                    ),
                    const SizedBox(height: 8),
                    InfoRow(icon: Icons.event_outlined, text: formatSlipPeriod(slip)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColor.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
