import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/shift-swap/presentation/shift_swap_page.dart';
import 'package:intl/intl.dart';


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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 56,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<AttendanceHistoryCubit>()
                          .fetchHistory(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // null berarti tombolnya mati sendiri. Riwayat masa depan tidak
            // ada isinya, dan tombol yang selalu bisa ditekan membuat orang
            // menggeser terus tanpa menemukan apa pun.
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Hadir',
            value: '${summary.presentDays}',
            color: Colors.green.shade700,
          ),
          _SummaryItem(
            label: 'Terlambat',
            value: '${summary.lateDays}',
            color: Colors.orange.shade800,
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
            color: summary.absentDays > 0
                ? Theme.of(context).colorScheme.error
                : null,
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          if (caption != null)
            Text(
              caption!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 56,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal di $month',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Anda tidak punya shift yang dijadwalkan di bulan ini. Kalau '
              'seharusnya ada, hubungi HR untuk memeriksa roster.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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

  /// Baris mana yang bisa ditukar shiftnya.
  ///
  /// Hanya yang shiftnya BELUM dimulai. Riwayat menampilkan masa lalu dan
  /// masa depan di bulan yang sama — dan tukar shift cuma masuk akal untuk
  /// yang belum terjadi.
  ///
  /// Status 'scheduled' berarti shiftnya belum berakhir, tapi itu belum
  /// cukup: shift hari ini yang sudah dimulai juga 'scheduled'. Yang dipakai
  /// jam mulainya, bukan statusnya.
  bool get _canSwap {
    if (row.scheduledStart == null) return false;

    try {
      return DateTime.parse(row.scheduledStart!).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _openSwap(BuildContext context) async {
    if (row.employeeShiftId == null) return;

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ShiftSwapFormPage(
          employeeShiftId: row.employeeShiftId!,
          myShiftName: row.shiftName ?? 'Shift',
          myWorkDate: row.workDate ?? '',
        ),
      ),
    );

    // Riwayat dimuat ulang meski jadwalnya belum berubah — pengajuan masih
    // menunggu rekan dan atasan. Yang dimuat ulang bukan hasilnya, melainkan
    // kepastian bahwa tadi berhasil terkirim.
    if (submitted == true && context.mounted) {
      context.read<AttendanceHistoryCubit>().fetchHistory();
    }
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

  ({String label, Color color, IconData icon}) _badge(BuildContext context) {
    switch (row.status) {
      case 'present':
        return (
          label: 'Hadir',
          color: Colors.green.shade700,
          icon: Icons.check_circle_outline,
        );

      // Terlambat tetap hadir, warnanya saja yang beda. Ikon silang untuk
      // orang yang datang dan bekerja itu penghakiman, bukan informasi.
      case 'late':
        return (
          label: 'Hadir, terlambat',
          color: Colors.orange.shade800,
          icon: Icons.check_circle_outline,
        );
      case 'incomplete':
        return (
          label: 'Tidak clock out',
          color: Colors.orange.shade800,
          icon: Icons.error_outline,
        );
      case 'absent':
        return (
          label: 'Tidak absen',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.cancel_outlined,
        );
      case 'on_leave':
        return (
          label: row.leaveTypeName ?? 'Cuti',
          color: Colors.blue.shade700,
          icon: Icons.beach_access_outlined,
        );
      default:
        return (
          label: 'Belum berakhir',
          color: Theme.of(context).disabledColor,
          icon: Icons.schedule,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge(context);
    final late = row.lateMinutes ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(badge.icon, color: badge.color, size: 22),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        row.shiftName ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: badge.color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                  if (late > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Terlambat $late menit',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade900,
                          ),
                    ),
                  ],

                  if (row.needsReview == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ditandai untuk ditinjau HR',
                      style: Theme.of(context).textTheme.labelSmall,
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

                  // Tukar shift untuk yang BELUM terjadi, koreksi untuk yang
                  // sudah. Keduanya tidak pernah muncul bersamaan di satu
                  // baris — syaratnya saling meniadakan.
                  if (_canSwap) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _openSwap(context),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Tukar Shift'),
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
                Text(
                  _time(row.clockInAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _time(row.clockOutAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}