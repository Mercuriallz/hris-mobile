import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../cubit/attendance_request_cubit.dart';
import '../cubit/attendance_request_state.dart';
import '../model/attendance_request_model.dart';
import '../model/create_attendance_request_model.dart';

/// Daftar pengajuan koreksi milik sendiri, beserta statusnya.
///
/// Ada karena pengajuan yang terkirim lalu hilang dari pandangan membuat orang
/// mengajukan ulang — dan pengajuan kembar untuk shift yang sama menyulitkan
/// penyetuju, bukan pengaju.
class AttendanceRequestListPage extends StatefulWidget {
  const AttendanceRequestListPage({super.key});

  @override
  State<AttendanceRequestListPage> createState() =>
      _AttendanceRequestListPageState();
}

class _AttendanceRequestListPageState extends State<AttendanceRequestListPage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceRequestCubit>().fetchMyRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Koreksi')),
      body: BlocBuilder<AttendanceRequestCubit, AttendanceRequestState>(
        // State pengiriman tidak boleh membangun ulang layar ini — dia milik
        // formulir, dan di sini cuma akan mengosongkan daftarnya sesaat.
        buildWhen: (previous, current) =>
            current is! AttendanceRequestSubmitting &&
            current is! AttendanceRequestSubmitted &&
            current is! AttendanceRequestSubmitError,

        builder: (context, state) {
          if (state is AttendanceRequestLoading ||
              state is AttendanceRequestInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AttendanceRequestError) {
            return ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<AttendanceRequestCubit>().fetchMyRequests(),
            );
          }

          final loaded = state as AttendanceRequestLoaded;

          if (loaded.requests.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Belum ada pengajuan',
              message: 'Buka tab Riwayat, lalu ketuk Ajukan Koreksi di hari '
                  'yang absensinya perlu diperbaiki.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AttendanceRequestCubit>().fetchMyRequests(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loaded.requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _RequestTile(request: loaded.requests[index]),
            ),
          );
        },
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final AttendanceRequestData request;

  const _RequestTile({required this.request});

  static final _dayFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm');

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

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final workDate = request.employeeShift?.workDate;

    String time(String? iso) => iso == null
        ? '--:--'
        : _timeFormat.format(DateTime.parse(iso).toLocal());

    final times = [
      if (request.proposedClockInAt != null)
        'Masuk ${time(request.proposedClockInAt)}',
      if (request.proposedClockOutAt != null)
        'Pulang ${time(request.proposedClockOutAt)}',
    ].join('  ·  ');

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
                    workDate == null
                        ? '-'
                        : _dayFormat.format(DateTime.parse(workDate)),
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

            const SizedBox(height: 8),

            Text(
              AttendanceRequestTypes.labels[request.type] ?? request.type ?? '',
              style: AppText.body,
            ),

            if (times.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(times, style: AppText.caption),
            ],

            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
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

            // Alasan penolakan ditampilkan paling menonjol, dengan latar merah.
            //
            // Ini yang pertama dicari orang begitu pengajuannya ditolak —
            // menyembunyikannya di balik badge "Ditolak" berarti dia akan
            // bertanya ke HR, dan itu persis yang ingin dihindari dengan
            // adanya aplikasi ini.
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
              const SizedBox(height: 10),
              Text(
                'Menunggu keputusan atasan Anda. Absensi belum berubah sampai '
                'HR ikut menyetujui.',
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