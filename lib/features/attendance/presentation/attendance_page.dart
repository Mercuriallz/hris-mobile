import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:hris_mobile/features/attendance-history/presentation/attendance_history_page.dart';
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

/// Layar absensi.
///
/// Ini satu-satunya layar yang dibuka orang setiap hari, dua kali sehari, dan
/// biasanya sambil berjalan masuk kantor. Karena itu bentuknya bukan daftar
/// seragam: satu kartu besar untuk shift yang berlaku SEKARANG, dan sisanya
/// jadi baris kecil di bawah.
///
/// Daftar seragam memaksa orang memindai untuk menemukan mana yang relevan —
/// padahal jam 8 pagi dia cuma punya satu pertanyaan.
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Timer? _clock;
  DateTime _now = DateTime.now();
  String _name = '';

  /// Status wajah, diambil sekali saat layar dibuka.
  ///
  /// Disimpan di layar, bukan di state cubit. Alasannya: ini cuma menentukan
  /// apakah kamera perlu dibuka, dan menaruhnya di state absensi berarti
  /// setiap pemuatan ulang kartu ikut memuat status wajah — padahal
  /// kebijakannya tidak berubah setiap menit.
  FaceStatusData? _faceStatus;

  /// Ringkasan bulan ini, pengajuan menunggu, dan jadwal ke depan.
  ///
  /// Dimuat terpisah dan tidak menahan kartu shift. Kartu shift adalah alasan
  /// orang membuka layar ini — ringkasan yang gagal dimuat tidak boleh
  /// menghalangi tombol clock in.
  SummaryData? _summary;

  @override
  void initState() {
    super.initState();
    _loadFaceStatus();
    _loadSummary();
    context.read<AttendanceCubit>().fetchShifts();
    _loadName();

    // Jam berdetak setiap sepuluh detik.
    //
    // Bukan hiasan: orang yang absen mepet jam masuk perlu tahu jam yang
    // dipakai aplikasi, bukan jam di kepalanya. Dan jam yang bergerak
    // meyakinkan bahwa layarnya hidup — bukan tangkapan layar yang membeku.
    _clock = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _loadName() async {
    final name = await SecureStorageService().read("fullname");
    if (mounted) setState(() => _name = name ?? '');
  }

  /// Status wajah tidak menahan tampilnya layar.
  ///
  /// Gagal berarti _faceStatus tetap null, dan clock in berjalan tanpa
  /// verifikasi — backend yang memutuskan apakah itu masalah. Layar absensi
  /// tidak boleh gagal dibuka karena satu permintaan tambahan.
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

  /// Mengambil foto untuk verifikasi wajah, kalau memang dibutuhkan.
  ///
  /// Mengembalikan null berarti lanjut tanpa verifikasi — dan itu sah kalau
  /// verifikasinya mati atau wajahnya belum terdaftar. Mengembalikan string
  /// kosong berarti orangnya membatalkan, dan absensinya tidak diteruskan.
  Future<String?> _photoForVerification() async {
    final status = _faceStatus;

    // Verifikasi mati: kamera tidak dibuka sama sekali. Membuka kamera untuk
    // foto yang tidak akan diperiksa berarti menambah satu langkah tanpa
    // menambah apa pun.
    if (status == null || !status.needsVerification) return null;

    // Belum terdaftar. Kalau wajib, backend akan menolak — jadi lebih baik
    // diarahkan mendaftar sekarang daripada ditolak setelah mengambil foto.
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

    // Batal berarti batal. Melanjutkan tanpa verifikasi di sini akan memberi
    // jalan keluar yang membatalkan seluruh gunanya verifikasi.
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

  /// Kartu yang paling relevan sekarang.
  ///
  /// Yang bisa diketuk selalu menang atas yang cuma bisa dilihat. Orang yang
  /// punya shift malam kemarin yang belum di-clock-out dan shift pagi hari ini
  /// perlu melihat yang belum selesai lebih dulu — kalau tidak, dia clock in
  /// shift baru dan shift lamanya menggantung selamanya.
  ShiftCard? _pickPrimary(List<ShiftCard> cards) {
    if (cards.isEmpty) return null;

    final actionable = cards.where(
      (c) => (c.canClockOut ?? false) || (c.canClockIn ?? false),
    );
    if (actionable.isNotEmpty) {
      // Clock out lebih dulu daripada clock in.
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
          final others =
              cards.where((c) => c.employeeShiftId != primary?.employeeShiftId);

          return RefreshIndicator(
            onRefresh: () async {
              // Tarik ke bawah menyegarkan keduanya. Menyegarkan kartu shift
              // saja berarti ringkasan di bawahnya tetap menampilkan angka
              // kemarin — dan tidak ada yang memberi tahu bahwa itu lama.
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
                    child: state is AttendanceLoading ||
                            state is AttendanceInitial
                        ? const _LoadingCard()
                        : state is AttendanceError
                            ? _ErrorCard(
                                message: state.message,
                                onRetry: () => context
                                    .read<AttendanceCubit>()
                                    .fetchShifts(),
                              )
                            : primary == null
                                ? const _NoShiftCard()
                                : _PrimaryShiftCard(
                                    card: primary,
                                    now: _now,
                                    isProcessing: state is AttendanceLoaded &&
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

                // Ringkasan ditaruh SETELAH kartu shift, bukan sebelum.
                //
                // Kartu shift adalah alasan orang membuka layar ini — tombol
                // clock in harus terlihat tanpa menggulir. Ringkasan yang
                // dipasang di atasnya akan mendorong tombolnya keluar layar
                // di HP kecil.
                if (_summary != null) ...[
                  _PendingBanner(pending: _summary!.pendingRequests),
                  _MonthSummary(attendance: _summary!.attendance),
                  _UpcomingShifts(
                    shifts: _summary!.upcomingShifts ?? [],
                    now: _now,
                  ),
                ],

                // Menu, bukan ikon di header.
                //
                // Ikon kecil di pojok mengandalkan orang menemukannya sendiri.
                // Baris bernama dengan keterangan di bawahnya bisa dibaca
                // sekali lalu diingat — dan Pengajuan Koreksi yang sebelumnya
                // tersembunyi di dalam Riwayat sekarang punya jalannya sendiri.
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
                          subtitle:
                              'Status pengajuan yang sudah Anda kirim',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AttendanceRequestListPage(),
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
          // Pesan penolakan sering panjang — "Anda berada 340 meter dari Head
          // Office, di luar radius 150 meter" perlu waktu dibaca.
          duration: Duration(seconds: isError ? 6 : 3),
        ),
      );
  }
}

/// Bidang biru di atas, dengan jam yang berdetak.
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
              Text(
                name,
                style: AppText.h1.copyWith(color: Colors.white),
              ),
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

/// Kartu utama: shift yang berlaku sekarang, dengan tombol besar.
class _PrimaryShiftCard extends StatelessWidget {
  final ShiftCard card;
  final DateTime now;
  final bool isProcessing;

  /// Mengambil foto untuk verifikasi wajah, kalau memang dibutuhkan.
  ///
  /// null berarti verifikasi tidak dibutuhkan dan absensi diteruskan apa
  /// adanya. String kosong berarti dibatalkan, dan absensinya tidak
  /// diteruskan.
  ///
  /// Diteruskan sebagai fungsi, bukan dikerjakan di dalam kartu: kamera dan
  /// navigasi butuh state layar, dan kartu ini sengaja tanpa state supaya
  /// bisa dibangun ulang murah setiap jam berdetak.
  final Future<String?> Function() onNeedPhoto;

  const _PrimaryShiftCard({
    required this.card,
    required this.now,
    required this.isProcessing,
    required this.onNeedPhoto,
  });

  static final _timeFormat = DateFormat('HH:mm');

  String _time(String? iso) => iso == null
      ? '--:--'
      : _timeFormat.format(DateTime.parse(iso).toLocal());

  ({String label, StatusTone tone, IconData icon}) get _badge {
    switch (card.state) {
      case 'done':
        return (
          label: 'Selesai',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline
        );
      case 'open':
        return (
          label: 'Sedang bekerja',
          tone: StatusTone.info,
          icon: Icons.play_circle_outline
        );
      case 'missed':
        return (
          label: 'Terlewat',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined
        );
      case 'incomplete':
        return (
          label: 'Tidak lengkap',
          tone: StatusTone.danger,
          icon: Icons.error_outline
        );
      default:
        return (
          label: 'Belum absen',
          tone: StatusTone.neutral,
          icon: Icons.schedule
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
            text: '${_time(card.startAt)} – ${_time(card.endAt)}'
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
                  _Stat(
                    label: 'PULANG',
                    value: _time(attendance.clockOutAt),
                  ),
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
                      style: AppText.caption
                          .copyWith(color: AppColor.warning),
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
                      // String kosong berarti dibatalkan atau kameranya
                      // gagal. null berarti verifikasi memang tidak
                      // dibutuhkan.
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
                backgroundColor:
                    canClockIn ? AppColor.primary : AppColor.warning,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            // Kalau tombolnya tidak ada, alasannya harus disebut. Tombol yang
            // hilang tanpa penjelasan terbaca sebagai kerusakan.
            Text(
              switch (card.state) {
                'upcoming' =>
                  'Clock in bisa mulai ${_time(card.clockInOpensAt)}.',
                'missed' =>
                  'Shift ini berakhir tanpa absensi. Ajukan koreksi lewat tab Riwayat.',
                'incomplete' =>
                  'Batas clock out sudah lewat. Ajukan koreksi lewat tab Riwayat.',
                _ => 'Shift ini sudah selesai.',
              },
              style: AppText.caption,
            ),
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
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        color: AppColor.border,
      );
}

/// Shift lain: kemarin yang belum selesai, atau besok.
class _SecondaryShiftRow extends StatelessWidget {
  final ShiftCard card;
  final DateTime now;

  const _SecondaryShiftRow({required this.card, required this.now});

  static final _timeFormat = DateFormat('HH:mm');
  static final _dayFormat = DateFormat('EEE, d MMM', 'id_ID');

  String _time(String? iso) => iso == null
      ? '--:--'
      : _timeFormat.format(DateTime.parse(iso).toLocal());

  String get _dateLabel {
    if (card.workDate == null) return '';

    final date = DateTime.parse(card.workDate!);
    final diff = DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

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
                  // Keterangan di bawah judulnya ada supaya orang tahu apa
                  // yang akan dia temukan sebelum mengetuk. Menu yang cuma
                  // berisi nama memaksa orang mencoba satu per satu.
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

/// Spanduk pengajuan yang masih menunggu.
///
/// Muncul paling atas di antara ringkasan, dan hanya kalau ada. Ini
/// satu-satunya bagian yang bisa menuntut tindakan hari ini — sisanya cuma
/// keadaan.
class _PendingBanner extends StatelessWidget {
  final SummaryPending? pending;

  const _PendingBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    final total = pending?.total ?? 0;
    if (total == 0) return const SizedBox.shrink();

    final oldest = pending?.oldestDays ?? 0;
    final types = pending?.byType ?? [];

    // Yang menggantung lebih dari tiga hari diberi warna berbeda. Lima
    // pengajuan yang masuk pagi ini bukan masalah; satu yang menggantung
    // sembilan hari adalah masalah — dan keduanya terlihat sama kalau yang
    // ditampilkan cuma angka totalnya.
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
                      ...types.map((t) =>
                          '${kRequestTypeLabels[t.requestType] ?? t.requestType} ${t.count}'),
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

    // Bulan tanpa shift terjadwal tidak ditampilkan sama sekali. Deretan nol
    // tidak memberi tahu apa pun, dan yang membacanya akan mengira datanya
    // gagal dimuat.
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

            // Total menit terlambat disebut hanya kalau ada. Angka nol di
            // situ cuma menambah baris yang tidak berarti.
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

/// Pemisah tipis antar statistik, senada dengan _Divider di kartu shift.
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
          Text(
            value,
            style: AppText.h1.copyWith(fontSize: 20, color: color),
          ),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

/// Jadwal beberapa hari ke depan.
class _UpcomingShifts extends StatelessWidget {
  final List<UpcomingShift> shifts;
  final DateTime now;

  const _UpcomingShifts({required this.shifts, required this.now});

  static final _dayFormat = DateFormat('EEE', 'id_ID');
  static final _dateFormat = DateFormat('d MMM', 'id_ID');

  /// "Hari ini" dan "Besok" dibaca lebih cepat daripada "Rab, 12 Sep" —
  /// dan itu yang biasanya ingin diketahui orang dari kartu paling kiri.
  String _dayLabel(DateTime date) {
    final diff = DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

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

        // Menggulir menyamping, bukan daftar menurun.
        //
        // Tujuh baris menurun akan mendorong menu di bawahnya keluar layar.
        // Menyamping menjaga tingginya tetap, dan jadwal ke depan memang
        // dibaca sekilas — bukan diperiksa satu per satu.
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

              // Kartu paling kiri selalu yang paling dekat — ditonjolkan
              // supaya mata langsung tahu ke mana harus melihat duluan.
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
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: accent),
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