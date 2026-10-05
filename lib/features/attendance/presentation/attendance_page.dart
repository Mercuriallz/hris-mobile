import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:hris_mobile/features/attendance-history/presentation/attendance_history_page.dart';
import 'package:hris_mobile/features/overtime/presentation/overtime_page.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../helper/storage.dart';
import '../../attendance_request/presentation/attendance_request_list_page.dart';
import '../../face/model/face_status_model.dart';
import '../../face/presentation/face_enroll_page.dart';
import '../../face/presentation/face_scan_page.dart';
import '../model/summary_model.dart';
import '../repository/summary_repository.dart';
import '../../face/repository/face_repository.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';
import '../model/shift_card_model.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Timer? _clock;
  DateTime _now = DateTime.now();
  String _name = '';


  FaceStatusData? _faceStatus;

  
  SummaryData? _summary;

  @override
  void initState() {
    super.initState();
    _loadFaceStatus();
    _loadSummary();
    context.read<AttendanceCubit>().fetchShifts();
    _loadName();

  
    _clock = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _loadName() async {
    final name = await SecureStorageService().read("fullname");
    if (mounted) setState(() => _name = name ?? '');
  }

  
  Future<void> _loadSummary() async {
    final result = await SummaryRepository().getSummary();

    if (!mounted) return;

    result.fold(
      (l) => debugPrint('Ringkasan gagal: $l'),
      (response) => setState(() => _summary = response.data),
    );
  }

  Future<void> _loadFaceStatus() async {
    final result = await FaceRepository().status();

    if (!mounted) return;

    result.fold(
      (_) {},
      (response) => setState(() => _faceStatus = response.data),
    );
  }


  Future<String?> _photoForVerification() async {
    final status = _faceStatus;


    if (status == null || !status.needsVerification) return null;

  
    if (status.enrolled != true) {
      if (status.isRequired == true) {
        final enrolled = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const FaceEnrollPage()),
        );

        if (enrolled != true) return '';
        await _loadFaceStatus();
      } else {
        return null;
      }
    }

    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceScanPage(
          title: 'Verifikasi Wajah',
          instruction: 'Posisikan wajah di dalam bingkai',
        ),
      ),
    );

   
    return path ?? '';
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String get _greeting {
    final hour = _now.hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }


  ShiftCard? _pickPrimary(List<ShiftCard> cards) {
    if (cards.isEmpty) return null;

    final actionable = cards.where(
      (c) => (c.canClockOut ?? false) || (c.canClockIn ?? false),
    );
    if (actionable.isNotEmpty) {
      final pending = actionable.where((c) => c.canClockOut ?? false);
      return pending.isNotEmpty ? pending.first : actionable.first;
    }

    final today = DateFormat('yyyy-MM-dd').format(_now);
    final todayCard = cards.where((c) => c.workDate == today);
    if (todayCard.isNotEmpty) return todayCard.first;

    return cards.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceActionSuccess) {
            _snack(state.message, isError: false);
          }
          if (state is AttendanceActionError) {
            _snack(state.message, isError: true);
          }
        },
        buildWhen: (previous, current) =>
            current is! AttendanceActionSuccess &&
            current is! AttendanceActionError,
        builder: (context, state) {
          final cards = state is AttendanceLoaded ? state.cards : <ShiftCard>[];
          final primary = _pickPrimary(cards);
          final others = cards.where(
            (c) => c.employeeShiftId != primary?.employeeShiftId,
          );

          return RefreshIndicator(
            onRefresh: () async {
            
              context.read<AttendanceCubit>().fetchShifts(silent: true);
              await _loadSummary();
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(greeting: _greeting, name: _name, now: _now),

                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        state is AttendanceLoading || state is AttendanceInitial
                        ? const _LoadingCard()
                        : state is AttendanceError
                        ? _ErrorCard(
                            message: state.message,
                            onRetry: () =>
                                context.read<AttendanceCubit>().fetchShifts(),
                          )
                        : primary == null
                        ? const _NoShiftCard()
                        : _PrimaryShiftCard(
                            card: primary,
                            now: _now,
                            isProcessing:
                                state is AttendanceLoaded &&
                                state.processingShiftId ==
                                    primary.employeeShiftId,
                            onNeedPhoto: _photoForVerification,
                          ),
                  ),
                ),

                if (others.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text('SHIFT LAINNYA', style: AppText.label),
                  ),
                  ...others.map(
                    (card) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _SecondaryShiftRow(card: card, now: _now),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

         
                if (_summary != null) ...[
                  _PendingBanner(pending: _summary!.pendingRequests),
                  _MonthSummary(attendance: _summary!.attendance),
                  _UpcomingShifts(
                    shifts: _summary!.upcomingShifts ?? [],
                    now: _now,
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text('LAINNYA', style: AppText.label),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColor.border),
                    ),
                    child: Column(
                      children: [
                        _MenuRow(
                          icon: Icons.history_rounded,
                          title: 'Riwayat Absensi',
                          subtitle:
                              'Rekap kehadiran per bulan, dan ajukan koreksi '
                              'kalau ada yang keliru',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceHistoryPage(),
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        _MenuRow(
                          icon: Icons.inbox_outlined,
                          title: 'Pengajuan Koreksi',
                          subtitle: 'Status pengajuan yang sudah Anda kirim',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceRequestListPage(),
                            ),
                          ),
                        ),
                        _MenuRow(
                          icon: Icons.more_time_outlined,
                          title: 'Lembur',
                          subtitle:
                              'Laporkan lembur dan lihat jam setara bulan ini',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OvertimePage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _snack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColor.danger : AppColor.success,
         
          duration: Duration(seconds: isError ? 6 : 3),
        ),
      );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String name;
  final DateTime now;

  const _Header({
    required this.greeting,
    required this.name,
    required this.now,
  });

  static final _timeFormat = DateFormat('HH:mm');
  static final _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primary, AppColor.primaryDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'assets/images/workonix-logo-dark.svg',
              height: 40,
            ),
            const SizedBox(height: 12),
            Text(
              name.isEmpty ? greeting : '$greeting,',
              style: AppText.body.copyWith(color: Colors.white70),
            ),
            if (name.isNotEmpty)
              Text(name, style: AppText.h1.copyWith(color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeFormat.format(now),
                  style: AppText.display.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _dateFormat.format(now),
                    style: AppText.caption.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryShiftCard extends StatelessWidget {
  final ShiftCard card;
  final DateTime now;
  final bool isProcessing;

 
  final Future<String?> Function() onNeedPhoto;

  const _PrimaryShiftCard({
    required this.card,
    required this.now,
    required this.isProcessing,
    required this.onNeedPhoto,
  });

  static final _timeFormat = DateFormat('HH:mm');

  String _time(String? iso) =>
      iso == null ? '--:--' : _timeFormat.format(DateTime.parse(iso).toLocal());

  ({String label, StatusTone tone, IconData icon}) get _badge {
    switch (card.state) {
      case 'done':
        return (
          label: 'Selesai',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        );
      case 'open':
        return (
          label: 'Sedang bekerja',
          tone: StatusTone.info,
          icon: Icons.play_circle_outline,
        );
      case 'missed':
        return (
          label: 'Terlewat',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        );
      case 'incomplete':
        return (
          label: 'Tidak lengkap',
          tone: StatusTone.danger,
          icon: Icons.error_outline,
        );
      default:
        return (
          label: 'Belum absen',
          tone: StatusTone.neutral,
          icon: Icons.schedule,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canClockIn = card.canClockIn ?? false;
    final canClockOut = card.canClockOut ?? false;
    final attendance = card.attendance;
    final badge = _badge;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.border),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryDark.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.shiftName ?? 'Shift',
                  style: AppText.h1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: badge.label,
                tone: badge.tone,
                icon: badge.icon,
              ),
            ],
          ),

          const SizedBox(height: 12),

          InfoRow(
            icon: Icons.schedule,
            text:
                '${_time(card.startAt)} – ${_time(card.endAt)}'
                '${card.crossesMidnight == true ? ' (lewat tengah malam)' : ''}',
          ),
          const SizedBox(height: 6),
          InfoRow(
            icon: Icons.location_on_outlined,
            text: card.office == null
                ? 'Tanpa kantor tetap — absensi tidak dibandingkan radius'
                : '${card.office!.name} · radius ${card.office!.radiusMeters} m',
          ),

          if (attendance != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColor.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _Stat(label: 'MASUK', value: _time(attendance.clockInAt)),
                  _Divider(),
                  _Stat(label: 'PULANG', value: _time(attendance.clockOutAt)),
                  _Divider(),
                  _Stat(
                    label: 'TERLAMBAT',
                    value: (attendance.lateMinutes ?? 0) == 0
                        ? '–'
                        : '${attendance.lateMinutes}m',
                    tone: (attendance.lateMinutes ?? 0) > 0
                        ? AppColor.warning
                        : null,
                  ),
                ],
              ),
            ),
          ],

          if (attendance?.needsReview == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.warningSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColor.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Absensi ini ditandai untuk ditinjau HR.',
                      style: AppText.caption.copyWith(color: AppColor.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (canClockIn || canClockOut) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isProcessing
                  ? null
                  : () async {
                      final id = card.employeeShiftId!;

                      final photoPath = await onNeedPhoto();
                    
                      if (photoPath == '') return;
                      if (!context.mounted) return;

                      final cubit = context.read<AttendanceCubit>();
                      canClockIn
                          ? cubit.clockIn(id, photoPath: photoPath)
                          : cubit.clockOut(id, photoPath: photoPath);
                    },
              icon: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      canClockIn ? Icons.fingerprint : Icons.logout,
                      size: 22,
                    ),
              label: Text(
                isProcessing
                    ? 'Membaca lokasi...'
                    : (canClockIn ? 'Clock In' : 'Clock Out'),
                style: AppText.bodyStrong.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: canClockIn
                    ? AppColor.primary
                    : AppColor.warning,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
          
            Text(switch (card.state) {
              'upcoming' =>
                'Clock in bisa mulai ${_time(card.clockInOpensAt)}.',
              'missed' =>
                'Shift ini berakhir tanpa absensi. Ajukan koreksi lewat tab Riwayat.',
              'incomplete' =>
                'Batas clock out sudah lewat. Ajukan koreksi lewat tab Riwayat.',
              _ => 'Shift ini sudah selesai.',
            }, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const _Stat({required this.label, required this.value, this.tone});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppText.bodyStrong.copyWith(fontSize: 16, color: tone),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: AppColor.border);
}

/// Shift lain: kemarin yang belum selesai, atau besok.
class _SecondaryShiftRow extends StatelessWidget {
  final ShiftCard card;
  final DateTime now;

  const _SecondaryShiftRow({required this.card, required this.now});

  static final _timeFormat = DateFormat('HH:mm');
  static final _dayFormat = DateFormat('EEE, d MMM', 'id_ID');

  String _time(String? iso) =>
      iso == null ? '--:--' : _timeFormat.format(DateTime.parse(iso).toLocal());

  String get _dateLabel {
    if (card.workDate == null) return '';

    final date = DateTime.parse(card.workDate!);
    final diff = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == -1) return 'Kemarin';
    if (diff == 1) return 'Besok';
    return _dayFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColor.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateLabel, style: AppText.label),
                  const SizedBox(height: 1),
                  Text(
                    card.shiftName ?? 'Shift',
                    style: AppText.bodyStrong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '${_time(card.startAt)} – ${_time(card.endAt)}',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _NoShiftCard extends StatelessWidget {
  const _NoShiftCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Tidak ada jadwal',
        message:
            'Anda tidak punya shift kemarin, hari ini, atau besok. Kalau '
            'seharusnya ada, hubungi HR untuk memeriksa roster.',
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ErrorState(message: message, onRetry: onRetry),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColor.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyStrong),
                  const SizedBox(height: 1),
                  
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColor.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}


class _PendingBanner extends StatelessWidget {
  final SummaryPending? pending;

  const _PendingBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    final total = pending?.total ?? 0;
    if (total == 0) return const SizedBox.shrink();

    final oldest = pending?.oldestDays ?? 0;
    final types = pending?.byType ?? [];

  
    final stale = oldest > 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stale ? AppColor.warningSurface : AppColor.primarySurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              stale ? Icons.hourglass_bottom : Icons.pending_actions_outlined,
              size: 18,
              color: stale ? AppColor.warning : AppColor.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total pengajuan menunggu approval',
                    style: AppText.bodyStrong.copyWith(
                      color: stale ? AppColor.warning : AppColor.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      ...types.map(
                        (t) =>
                            '${kRequestTypeLabels[t.requestType] ?? t.requestType} ${t.count}',
                      ),
                      // if (oldest > 0) 'tertua $oldest hari',
                    ].join(' · '),
                    style: AppText.caption.copyWith(
                      color: stale ? AppColor.warning : AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan absensi bulan berjalan.
class _MonthSummary extends StatelessWidget {
  final SummaryAttendance? attendance;

  const _MonthSummary({required this.attendance});

  static final _monthFormat = DateFormat('MMMM', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final data = attendance;


    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final late = data.lateDays ?? 0;
    final absent = data.absentDays ?? 0;
    final lateMinutes = data.totalLateMinutes ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColor.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _monthFormat.format(DateTime.now()).toUpperCase(),
              style: AppText.label,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _Stat2(
                  icon: Icons.check_circle_outline,
                  value: '${data.presentDays ?? 0}',
                  label: 'Hadir',
                  color: AppColor.success,
                ),
                _statDivider(),
                _Stat2(
                  icon: Icons.schedule,
                  value: '$late',
                  label: 'Terlambat',
                  color: late > 0 ? AppColor.warning : AppColor.textSecondary,
                ),
                _statDivider(),
                _Stat2(
                  icon: Icons.cancel_outlined,
                  value: '$absent',
                  label: 'Alpa',
                  color: absent > 0 ? AppColor.danger : AppColor.textSecondary,
                ),
                _statDivider(),
                _Stat2(
                  icon: Icons.beach_access_outlined,
                  value: '${data.leaveDays ?? 0}',
                  label: 'Cuti',
                  color: AppColor.textSecondary,
                ),
              ],
            ),

            
            if (lateMinutes > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Total keterlambatan ${_durationLabel(lateMinutes)}.',
                style: AppText.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes menit';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours jam' : '$hours jam $rest menit';
  }
}

Widget _statDivider() => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  child: _Divider(),
);

class _Stat2 extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Stat2({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppText.h1.copyWith(fontSize: 20, color: color)),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _UpcomingShifts extends StatelessWidget {
  final List<UpcomingShift> shifts;
  final DateTime now;

  const _UpcomingShifts({required this.shifts, required this.now});

  static final _dayFormat = DateFormat('EEE', 'id_ID');
  static final _dateFormat = DateFormat('d MMM', 'id_ID');


  String _dayLabel(DateTime date) {
    final diff = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    return _dayFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Text('JADWAL BERIKUTNYA', style: AppText.label),
        ),

        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shifts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              final date = DateTime.parse(shift.workDate ?? '');

       
              final isNext = index == 0;
              final accent = isNext ? AppColor.primary : AppColor.textSecondary;

              return Container(
                width: 128,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isNext ? AppColor.primarySurface : AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNext
                        ? AppColor.primary.withValues(alpha: 0.35)
                        : AppColor.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_dayLabel(date)}, ${_dateFormat.format(date)}',
                            style: AppText.label.copyWith(color: accent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shift.shiftName ?? '-',
                      style: AppText.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${_clock(shift.startAt)}–${_clock(shift.endAt)}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  static String _clock(String? iso) {
    if (iso == null) return '--:--';
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  }
}
