import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../model/timesheet_model.dart';

/// "1 jam 30 mnt", "45 mnt", "2 jam".
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m mnt';
  return m == 0 ? '$h jam' : '$h jam $m mnt';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
}

/// "Hari ini", "Kemarin", atau "Senin, 23 Nov 2026".
String dayLabel(String isoDate, {DateTime? now}) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final diff = today.difference(DateUtils.dateOnly(d)).inDays;
  final full = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(d);
  if (diff == 0) return 'Hari ini · ${DateFormat('d MMM', 'id_ID').format(d)}';
  if (diff == 1) return 'Kemarin · ${DateFormat('d MMM', 'id_ID').format(d)}';
  return full;
}

/// Pengaturan tampil per visibilitas, dipakai kartu dan formulir.
({String label, String hint, IconData icon, StatusTone tone}) visibilityInfo(String v) {
  switch (v) {
    case 'team':
      return (
        label: 'Team',
        hint: 'Rekan satu departemen',
        icon: Icons.groups_2_outlined,
        tone: StatusTone.info,
      );
    case 'all':
      return (
        label: 'All',
        hint: 'Semua karyawan',
        icon: Icons.public,
        tone: StatusTone.success,
      );
    default:
      return (
        label: 'Private',
        hint: 'Hanya saya',
        icon: Icons.lock_outline,
        tone: StatusTone.neutral,
      );
  }
}

/// Tab berbentuk pil. Lebih ringan daripada TabBar di AppBar dan warnanya
/// selalu mengikuti palet, di mode terang maupun gelap.
class PillTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const PillTabs({super.key, required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation!,
      builder: (context, _) {
        final selected = controller.animation!.value.round();
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.border),
          ),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == selected ? AppColor.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 13,
                          color: i == selected ? Colors.white : AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Kartu ringkasan di puncak tab Saya: total jam hari ini.
class TodayHero extends StatelessWidget {
  final int minutes;
  final int count;
  final bool loading;

  const TodayHero({super.key, required this.minutes, required this.count, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primary, AppColor.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HARI INI', style: AppText.label.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  loading ? '—' : (count == 0 ? 'Belum ada' : formatDuration(minutes)),
                  style: AppText.h1.copyWith(color: Colors.white, fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  loading
                      ? 'Memuat…'
                      : count == 0
                          ? 'Catat pekerjaan pertama Anda hari ini.'
                          : '$count aktivitas tercatat',
                  style: AppText.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

/// Header tanggal di atas sekelompok aktivitas.
class DayHeader extends StatelessWidget {
  final String isoDate;
  const DayHeader({super.key, required this.isoDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(dayLabel(isoDate).toUpperCase(), style: AppText.label),
    );
  }
}

/// Satu aktivitas. Di tab Saya ada menu ubah/hapus; di tab Tim dan Bersama
/// yang tampil adalah pemiliknya.
class ActivityCard extends StatelessWidget {
  final TimesheetActivity activity;
  final bool showOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActivityCard({
    super.key,
    required this.activity,
    this.showOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final vis = visibilityInfo(a.visibility);
    final hasMenu = onEdit != null || onDelete != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rel waktu: jam mulai menonjol, jam selesai di bawahnya.
              SizedBox(
                width: 46,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.startTime, style: AppText.bodyStrong),
                    Container(
                      width: 2,
                      height: 14,
                      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColor.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    Text(a.endTime, style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: hasMenu ? 0 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showOwner) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColor.primarySurface,
                              child: Text(
                                initialsOf(a.employeeName),
                                style: AppText.label.copyWith(color: AppColor.primary, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.departmentName == null
                                    ? a.employeeName
                                    : '${a.employeeName} · ${a.departmentName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        a.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong,
                      ),
                      if ((a.output ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.task_alt, size: 14, color: AppColor.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                a.output!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(label: vis.label, tone: vis.tone, icon: vis.icon),
                          StatusBadge(
                            label: formatDuration(a.durationMinutes),
                            tone: StatusTone.neutral,
                            icon: Icons.timelapse,
                          ),
                          _MetaText(icon: Icons.place_outlined, text: a.workLocation),
                          _MetaText(icon: Icons.repeat, text: a.workType),
                          if (a.shiftMode == 'shift')
                            const _MetaText(icon: Icons.wb_twilight, text: 'Shift'),
                        ],
                      ),
                      if ((a.approvedBy ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.verified_outlined, size: 14, color: AppColor.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Disetujui oleh ${a.approvedBy}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasMenu)
                PopupMenuButton<String>(
                  tooltip: 'Menu aktivitas',
                  icon: Icon(Icons.more_vert, color: AppColor.textSecondary, size: 20),
                  color: AppColor.surface,
                  onSelected: (v) => v == 'edit' ? onEdit?.call() : onDelete?.call(),
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18, color: AppColor.textPrimary),
                          const SizedBox(width: 10),
                          Text('Ubah', style: AppText.body),
                        ]),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColor.danger),
                          const SizedBox(width: 10),
                          Text('Hapus', style: AppText.body.copyWith(color: AppColor.danger)),
                        ]),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColor.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
        ),
      ],
    );
  }
}

/// Grafik batang 12 bulan: tahun lalu pudar, tahun ini penuh, bulan berjalan
/// diberi tanda. Dibuat dari widget biasa, bukan paket grafik, supaya tidak
/// menambah dependensi untuk satu layar.
class MonthlyBars extends StatelessWidget {
  final TimesheetSeries series;
  final int year;
  final int currentMonth; // 1..12, atau 0 kalau bukan tahun berjalan

  const MonthlyBars({super.key, required this.series, required this.year, required this.currentMonth});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  Widget build(BuildContext context) {
    final maxVal = [...series.current, ...series.previous, 1].reduce((a, b) => a > b ? a : b);
    const chartHeight = 120.0;

    final prevColor = AppColor.textDisabled.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Angka diletakkan tepat di atas batangnya, bukan di baris tersendiri.
        SizedBox(
          height: chartHeight + 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 12; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tinggi label tetap: teks sistem yang diperbesar tidak
                      // boleh mendorong kolom melewati tinggi grafik.
                      SizedBox(
                        height: 16,
                        child: series.current[i] > 0
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${series.current[i]}',
                                  style: AppText.label.copyWith(
                                    color: i + 1 == currentMonth ? AppColor.primary : AppColor.textSecondary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Bar(fraction: series.previous[i] / maxVal, color: prevColor, height: chartHeight),
                          const SizedBox(width: 2),
                          _Bar(
                            fraction: series.current[i] / maxVal,
                            color: i + 1 == currentMonth ? AppColor.primary : AppColor.primaryLight,
                            height: chartHeight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                child: Text(
                  _months[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppText.label.copyWith(
                    fontSize: 9,
                    color: i + 1 == currentMonth ? AppColor.primary : AppColor.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Legend(color: AppColor.primaryLight, text: '$year'),
            const SizedBox(width: 16),
            _Legend(color: prevColor, text: '${year - 1}'),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double height;
  const _Bar({required this.fraction, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    final h = fraction <= 0 ? 2.0 : (height * fraction).clamp(3.0, height);
    return Container(
      width: 8,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppText.caption),
      ],
    );
  }
}
