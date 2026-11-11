import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../model/warning_letter_model.dart';

/// Warna tingkat: makin tinggi makin pekat. Sama dengan dashboard HR.
Color warningLevelColor(String level) {
  switch (level) {
    case 'sp1':
      return const Color(0xFFD97706);
    case 'sp2':
      return const Color(0xFFEA580C);
    case 'sp3':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF64748B);
  }
}

StatusTone warningStatusTone(String status) {
  switch (status) {
    case 'active':
      return StatusTone.warning;
    case 'evaluation_due':
    case 'terminated':
      return StatusTone.danger;
    case 'improved':
      return StatusTone.success;
    default:
      return StatusTone.neutral;
  }
}

final _date = DateFormat('d MMM yyyy', 'id_ID');

String formatLetterDate(String iso) {
  if (iso.isEmpty) return '-';
  return _date.format(DateTime.parse(iso));
}

class WarningLevelBadge extends StatelessWidget {
  final String level;
  final bool large;

  const WarningLevelBadge({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: warningLevelColor(level),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kWarningLevelLabels[level] ?? level,
        style: (large ? AppText.bodyStrong : AppText.label).copyWith(color: Colors.white),
      ),
    );
  }
}

/// Kartu satu surat di daftar.
class WarningLetterCard extends StatelessWidget {
  final WarningLetter letter;
  final VoidCallback onTap;

  const WarningLetterCard({super.key, required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dimmed = !letter.isActive;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: dimmed ? AppColor.border : warningLevelColor(letter.level),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  WarningLevelBadge(level: letter.level),
                  const SizedBox(width: 8),
                  if (letter.isUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Baru', style: AppText.label.copyWith(color: Colors.white)),
                    ),
                  const Spacer(),
                  StatusBadge(label: letter.statusLabel, tone: warningStatusTone(letter.status)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                letter.violation,
                style: AppText.bodyStrong.copyWith(
                  color: dimmed ? AppColor.textSecondary : AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InfoRow(
                icon: Icons.event_outlined,
                text: letter.level == 'sp3'
                    ? 'Evaluasi ${formatLetterDate(letter.issuedDate)} – ${formatLetterDate(letter.expiresDate)}'
                    : 'Berlaku ${formatLetterDate(letter.issuedDate)} – ${formatLetterDate(letter.expiresDate)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
