import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../attendance_request/presentation/attendance_request_form_page.dart';
import '../../attendance_request/presentation/attendance_request_list_page.dart';
import '../cubit/attendance_history_cubit.dart';
import '../cubit/attendance_history_state.dart';
import '../model/attendance_history_model.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceHistoryCubit>().fetchHistory();
  }

  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            tooltip: 'Pengajuan koreksi saya',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AttendanceRequestListPage(),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
        builder: (context, state) {
          if (state is AttendanceHistoryLoading ||
              state is AttendanceHistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AttendanceHistoryError) {
            return ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<AttendanceHistoryCubit>().fetchHistory(),
            );
          }

          final loaded = state as AttendanceHistoryLoaded;
          final cubit = context.read<AttendanceHistoryCubit>();

          return Column(
            children: [
              // Penggeser bulan dan rangkuman selalu terlihat, tidak ikut
              // menggulir. Angka rangkumannya yang paling sering dicari —
              // menyuruh orang menggulir ke atas untuk melihatnya berarti
              // membuat yang paling penting jadi paling sulit dijangkau.
              _MonthSwitcher(
                label: _monthFormat.format(loaded.month),
                onPrevious: cubit.previousMonth,
                onNext: cubit.canGoNext ? cubit.nextMonth : null,
              ),
              _SummaryBar(summary: loaded.summary),

              Expanded(
                child: loaded.rows.isEmpty
                    ? _EmptyMonth(month: _monthFormat.format(loaded.month))
                    : RefreshIndicator(
                        onRefresh: () async => cubit.fetchHistory(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: loaded.rows.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _DayTile(row: loaded.rows[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _MonthSwitcher({
    required this.label,
    required this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(label, style: AppText.h2),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final HistorySummary summary;

  const _SummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(bottom: BorderSide(color: AppColor.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Hadir',
            value: '${summary.presentDays}',
            color: AppColor.success,
          ),
          _SummaryItem(
            label: 'Terlambat',
            value: '${summary.lateDays}',
            color: AppColor.warning,
            // Total menitnya penting justru karena jumlah harinya sendiri
            // tidak cukup: terlambat 3 hari masing-masing 2 menit berbeda
            // jauh dari terlambat 3 hari masing-masing sejam.
            caption: summary.totalLateMinutes > 0
                ? '${summary.totalLateMinutes} mnt'
                : null,
          ),
          _SummaryItem(
            label: 'Tidak absen',
            value: '${summary.absentDays}',
            color: summary.absentDays > 0 ? AppColor.danger : null,
          ),
          _SummaryItem(
            label: 'Cuti',
            value: '${summary.leaveDays}',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final String? caption;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.color,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppText.h1.copyWith(color: color, fontSize: 24),
          ),
          Text(label, style: AppText.label),
          if (caption != null)
            Text(caption!, style: AppText.label.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  final String month;

  const _EmptyMonth({required this.month});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.event_busy_outlined,
      title: 'Tidak ada jadwal di $month',
      message: 'Anda tidak punya shift yang dijadwalkan di bulan ini. Kalau '
          'seharusnya ada, hubungi HR untuk memeriksa roster.',
    );
  }
}

class _DayTile extends StatelessWidget {
  final AttendanceHistoryData row;

  const _DayTile({required this.row});

  static final _timeFormat = DateFormat('HH:mm');
  static final _dayFormat = DateFormat('EEE, d MMM', 'id_ID');

  String _time(String? iso) {
    if (iso == null) return '--:--';
    return _timeFormat.format(DateTime.parse(iso).toLocal());
  }

  /// Baris mana yang bisa diajukan koreksinya.
  ///
  /// Hanya yang absensinya memang bermasalah, dan hanya dalam 30 hari
  /// terakhir — backend menolak yang lebih lama, dan tombol yang selalu
  /// ditolak lebih buruk daripada tombol yang tidak ada.
  bool get _canRequestCorrection {
    if (row.status != 'absent' && row.status != 'incomplete') return false;
    if (row.workDate == null) return false;

    final age = DateTime.now()
        .difference(DateTime.parse(row.workDate!))
        .inDays;

    return age <= 30;
  }

  Future<void> _openForm(BuildContext context) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceRequestFormPage(row: row),
      ),
    );

    // Riwayat dimuat ulang hanya kalau pengajuannya benar-benar terkirim.
    // Statusnya belum berubah — pengajuan masih menunggu persetujuan — tapi
    // memuat ulang membuat orang tidak menebak apakah tadi berhasil.
    if (submitted == true && context.mounted) {
      context.read<AttendanceHistoryCubit>().fetchHistory();
    }
  }

  ({String label, StatusTone tone, IconData icon}) _badge() {
    switch (row.status) {
      case 'present':
        return (
          label: 'Hadir',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        );

      // Terlambat tetap hadir, nadanya saja yang beda. Ikon silang untuk orang
      // yang datang dan bekerja itu penghakiman, bukan informasi.
      case 'late':
        return (
          label: 'Hadir, terlambat',
          tone: StatusTone.warning,
          icon: Icons.check_circle_outline,
        );
      case 'incomplete':
        return (
          label: 'Tidak clock out',
          tone: StatusTone.warning,
          icon: Icons.error_outline,
        );
      case 'absent':
        return (
          label: 'Tidak absen',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        );
      case 'on_leave':
        return (
          label: row.leaveTypeName ?? 'Cuti',
          tone: StatusTone.info,
          icon: Icons.beach_access_outlined,
        );
      default:
        return (
          label: 'Belum berakhir',
          tone: StatusTone.neutral,
          icon: Icons.schedule,
        );
    }
  }

  ({Color fg, Color bg}) _toneColor(StatusTone tone) {
    switch (tone) {
      case StatusTone.success:
        return (fg: AppColor.success, bg: AppColor.successSurface);
      case StatusTone.warning:
        return (fg: AppColor.warning, bg: AppColor.warningSurface);
      case StatusTone.danger:
        return (fg: AppColor.danger, bg: AppColor.dangerSurface);
      case StatusTone.info:
        return (fg: AppColor.info, bg: AppColor.infoSurface);
      case StatusTone.neutral:
        return (fg: AppColor.textSecondary, bg: AppColor.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge();
    final tone = _toneColor(badge.tone);
    final late = row.lateMinutes ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tone.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(badge.icon, color: tone.fg, size: 19),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        row.workDate == null
                            ? '-'
                            : _dayFormat
                                .format(DateTime.parse(row.workDate!)),
                        style: AppText.bodyStrong,
                      ),
                      const SizedBox(width: 8),
                      Text(row.shiftName ?? '', style: AppText.caption),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.label,
                    style: AppText.caption.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (late > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Terlambat $late menit',
                      style: AppText.label.copyWith(color: AppColor.warning),
                    ),
                  ],

                  if (row.needsReview == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ditandai untuk ditinjau HR',
                      style: AppText.label,
                    ),
                  ],

                  // Tombol muncul hanya di baris yang memang bisa dikoreksi.
                  //
                  // Halaman yang menunjukkan masalah tanpa menyediakan jalan
                  // keluarnya akan mengirim orang ke HR — dan itu justru yang
                  // ingin dihindari dengan adanya aplikasi ini.
                  if (_canRequestCorrection) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Ajukan Koreksi'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Jam masuk dan keluar ditampilkan meski kosong, bukan
            // disembunyikan. Kolom yang hilang membuat baris-baris jadi tidak
            // sejajar, dan mata harus mencari ulang di setiap baris.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_time(row.clockInAt), style: AppText.bodyStrong),
                Text(_time(row.clockOutAt), style: AppText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}