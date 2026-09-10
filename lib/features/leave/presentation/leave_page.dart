import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../cubit/leave_cubit.dart';
import '../cubit/leave_state.dart';
import '../model/leave_model.dart';
import 'leave_form_page.dart';

/// Halaman cuti: saldo di atas, riwayat pengajuan di bawah.
///
/// Saldo ditaruh paling atas karena itu yang dicari orang saat membuka halaman
/// ini — pertanyaannya hampir selalu "sisa cuti saya berapa", bukan "apa saja
/// yang sudah saya ajukan".
class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  @override
  void initState() {
    super.initState();
    context.read<LeaveCubit>().fetchAll();
  }

  Future<void> _openForm(List<LeaveTypeData> types) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LeaveFormPage(types: types)),
    );

    if (submitted == true && mounted) {
      context.read<LeaveCubit>().fetchAll(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LeaveCubit, LeaveState>(
        builder: (context, state) {
          if (state is LeaveLoading || state is LeaveInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LeaveError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<LeaveCubit>().fetchAll(),
            );
          }

          final loaded = state as LeaveLoaded;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<LeaveCubit>().fetchAll(silent: true),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _BalanceHeader(balance: loaded.balance),

                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                      onPressed: loaded.types.isEmpty
                          ? null
                          : () => _openForm(loaded.types),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Ajukan Cuti'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ),

                if (loaded.types.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Belum ada jenis cuti yang aktif. Hubungi HR untuk '
                      'mengaktifkannya di pengaturan cuti.',
                      style: AppText.caption,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text('PENGAJUAN SAYA', style: AppText.label),
                ),

                if (loaded.requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyState(
                      icon: Icons.beach_access_outlined,
                      title: 'Belum ada pengajuan',
                      message: 'Pengajuan cuti Anda akan muncul di sini '
                          'beserta status persetujuannya.',
                    ),
                  )
                else
                  ...loaded.requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _RequestCard(request: request),
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
}

/// Kepala biru dengan sisa jatah sebagai angka terbesar di layar.
class _BalanceHeader extends StatelessWidget {
  final LeaveBalanceData balance;

  const _BalanceHeader({required this.balance});

  static final _periodFormat = DateFormat('d MMM yyyy', 'id_ID');

  String get _periodLabel {
    final start = balance.periodStart;
    final end = balance.periodEnd;

    // Rentang periode ditampilkan kalau ada, bukan cuma tahunnya.
    //
    // Untuk basis ulang tahun kerja, periode tiap karyawan berbeda — dan
    // "Periode 2026" untuk orang yang periodenya Juni 2026 sampai Mei 2027
    // menyesatkan.
    if (start != null && end != null) {
      return '${_periodFormat.format(DateTime.parse(start))} – '
          '${_periodFormat.format(DateTime.parse(end))}';
    }

    return 'Periode ${balance.periodYear ?? '-'}';
  }

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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Sisa jatah cuti',
              style: AppText.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatDays(balance.remaining),
                  style: AppText.display.copyWith(
                    color: Colors.white,
                    fontSize: 46,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'hari',
                  style: AppText.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _periodLabel,
              style: AppText.caption.copyWith(color: Colors.white70),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _HeaderStat(
                    label: 'JATAH',
                    value: formatDays(balance.entitled),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  _HeaderStat(
                    label: 'TERPAKAI',
                    value: formatDays(balance.used),
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

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppText.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            '$value hari',
            style: AppText.bodyStrong.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final LeaveRequestData request;

  const _RequestCard({required this.request});

  static final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
  static final _shortFormat = DateFormat('d MMM', 'id_ID');

  ({String label, StatusTone tone, IconData icon}) get _badge {
    switch (request.approvalStatus) {
      case 'approved':
        return (
          label: 'Disetujui',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        );
      case 'rejected':
        return (
          label: 'Ditolak',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        );
      case 'cancelled':
        return (
          label: 'Dibatalkan',
          tone: StatusTone.neutral,
          icon: Icons.block,
        );
      default:
        return (
          label: 'Menunggu',
          tone: StatusTone.warning,
          icon: Icons.hourglass_empty,
        );
    }
  }

  String get _dateRange {
    final start = request.startDate;
    final end = request.endDate;
    if (start == null) return '-';

    if (start == end) {
      return _dateFormat.format(DateTime.parse(start));
    }

    return '${_shortFormat.format(DateTime.parse(start))} – '
        '${_dateFormat.format(DateTime.parse(end!))}';
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.leaveType?.name ?? 'Cuti',
                    style: AppText.bodyStrong,
                  ),
                ),
                StatusBadge(
                  label: badge.label,
                  tone: badge.tone,
                  icon: badge.icon,
                ),
              ],
            ),

            const SizedBox(height: 6),

            InfoRow(icon: Icons.event, text: _dateRange),

            const SizedBox(height: 4),

            InfoRow(
              icon: Icons.timelapse,
              text: [
                '${formatDays(request.workingDays)} hari kerja',
                if ((request.unpaidDays ?? 0) > 0)
                  '${formatDays(request.unpaidDays)} tidak dibayar',
                if (request.halfDay == true) 'setengah hari',
              ].join(' · '),
            ),

            if (request.reason?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColor.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(request.reason!, style: AppText.caption),
              ),
            ],

            // Alasan penolakan ditampilkan paling menonjol.
            //
            // Ini yang pertama dicari orang begitu pengajuannya ditolak —
            // menyembunyikannya di balik badge "Ditolak" berarti dia akan
            // bertanya ke HR, dan itu persis yang ingin dihindari.
            if (request.approvalStatus == 'rejected') ...[
              const SizedBox(height: 10),
              _DecisionBox(
                tone: StatusTone.danger,
                icon: Icons.info_outline,
                title: 'Alasan penolakan',
                body: request.decisionNote?.isNotEmpty == true
                    ? request.decisionNote!
                    : 'Tidak ada alasan yang dituliskan. Tanyakan langsung ke '
                        '${request.decidedByName ?? 'atasan Anda'}.',
                footer: request.decidedByName == null
                    ? null
                    : 'Ditolak oleh ${request.decidedByName}',
              ),
              const SizedBox(height: 8),
              Text(
                'Potongan jatah cuti Anda sudah dikembalikan.',
                style: AppText.caption,
              ),
            ],

            if (request.approvalStatus == 'approved' &&
                request.decisionNote?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _DecisionBox(
                tone: StatusTone.success,
                icon: Icons.check_circle_outline,
                title: 'Catatan penyetuju',
                body: request.decisionNote!,
                footer: request.decidedByName == null
                    ? null
                    : 'Disetujui oleh ${request.decidedByName}',
              ),
            ],

            if (request.approvalStatus == 'pending' ||
                request.approvalStatus == null) ...[
              const SizedBox(height: 8),
              Text(
                'Saldo Anda sudah dipotong sejak pengajuan dikirim. Kalau '
                'nanti ditolak, potongannya dikembalikan otomatis.',
                style: AppText.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionBox extends StatelessWidget {
  final StatusTone tone;
  final IconData icon;
  final String title;
  final String body;
  final String? footer;

  const _DecisionBox({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  ({Color fg, Color bg}) get _colors {
    switch (tone) {
      case StatusTone.success:
        return (fg: AppColor.success, bg: AppColor.successSurface);
      case StatusTone.danger:
        return (fg: AppColor.danger, bg: AppColor.dangerSurface);
      case StatusTone.warning:
        return (fg: AppColor.warning, bg: AppColor.warningSurface);
      case StatusTone.info:
        return (fg: AppColor.info, bg: AppColor.infoSurface);
      case StatusTone.neutral:
        return (fg: AppColor.textSecondary, bg: AppColor.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: c.fg),
              const SizedBox(width: 6),
              Text(title, style: AppText.label.copyWith(color: c.fg)),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: AppText.body.copyWith(color: c.fg)),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(footer!, style: AppText.label.copyWith(color: c.fg)),
          ],
        ],
      ),
    );
  }
}