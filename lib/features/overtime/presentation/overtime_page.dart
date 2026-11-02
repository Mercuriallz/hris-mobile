import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:hris_mobile/features/overtime/cubit/overtime/overtime_cubit.dart';
import 'package:hris_mobile/features/overtime/cubit/overtime/overtime_state.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';

import '../model/overtime_model.dart';
import 'overtime_form_page.dart';

/// Daftar laporan lembur milik sendiri.
///
/// Berbeda dari cuti yang punya saldo di atas: lembur tidak punya jatah, jadi
/// tidak ada angka besar yang perlu ditonjolkan. Yang menggantikannya adalah
/// total jam setara bulan ini — itu yang menentukan besaran upahnya, dan itu
/// yang orang ingin tahu.
class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});

  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  @override
  void initState() {
    super.initState();
    context.read<OvertimeCubit>().fetchRequests();
  }

  Future<void> _openForm() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OvertimeFormPage()),
    );

    if (submitted == true && mounted) {
      context.read<OvertimeCubit>().fetchRequests(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lembur')),
      body: BlocBuilder<OvertimeCubit, OvertimeState>(
        builder: (context, state) {
          if (state is OvertimeLoading || state is OvertimeInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OvertimeError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<OvertimeCubit>().fetchRequests(),
            );
          }

          final requests = (state as OvertimeLoaded).requests;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<OvertimeCubit>().fetchRequests(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MonthTotal(requests: requests),

                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Laporkan Lembur'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),

                const SizedBox(height: 20),

                Text('LAPORAN SAYA', style: AppText.label),
                const SizedBox(height: 10),

                if (requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyState(
                      icon: Icons.more_time_outlined,
                      title: 'Belum ada laporan lembur',
                      message: 'Laporan lembur Anda akan muncul di sini '
                          'beserta status persetujuannya.',
                    ),
                  )
                else
                  ...requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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

/// Total jam setara bulan berjalan.
///
/// Hanya menghitung yang DISETUJUI. Yang masih menunggu belum tentu jadi, dan
/// menampilkannya sebagai total membuat orang mengira upahnya sudah pasti.
class _MonthTotal extends StatelessWidget {
  final List<OvertimeRequestData> requests;

  const _MonthTotal({required this.requests});

  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final prefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final thisMonth = requests.where(
      (r) => (r.workDate ?? '').startsWith(prefix),
    );

    final approved = thisMonth.where((r) => r.approvalStatus == 'approved');
    final pending = thisMonth.where(
      (r) => r.approvalStatus == 'pending' || r.approvalStatus == null,
    );

    final approvedHours = approved.fold<double>(
      0,
      (sum, r) => sum + (r.equivalentHours ?? 0),
    );
    final pendingHours = pending.fold<double>(
      0,
      (sum, r) => sum + (r.equivalentHours ?? 0),
    );

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _monthFormat.format(now).toUpperCase(),
            style: AppText.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatHours(approvedHours),
                style: AppText.display.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'jam setara disetujui',
                style: AppText.body.copyWith(color: Colors.white70),
              ),
            ],
          ),

          // Yang menunggu disebut terpisah, bukan digabung ke total.
          //
          // Menggabungkannya berarti angka besarnya turun saat ada yang
          // ditolak — dan orang yang melihat angkanya berkurang akan mengira
          // ada yang hilang.
          if (pendingHours > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${formatHours(pendingHours)} jam lagi menunggu keputusan.',
              style: AppText.caption.copyWith(color: Colors.white70),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            'Jam setara sudah dikali tarif hari dan tingkatannya, bukan jam '
            'sebenarnya.',
            style: AppText.caption.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final OvertimeRequestData request;

  const _RequestCard({required this.request});

  static final _dateFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');

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

  String _clock(String? iso) {
    if (iso == null) return '--:--';
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final dayLabel = kDayTypeLabels[request.dayType] ?? '';

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
                    request.workDate == null
                        ? '-'
                        : _dateFormat.format(DateTime.parse(request.workDate!)),
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

            InfoRow(
              icon: Icons.schedule,
              text: '${_clock(request.startAt)} – ${_clock(request.endAt)} '
                  '· ${formatHours(request.hours)} jam',
            ),

            const SizedBox(height: 4),

            // Jam setara dan jenis hari disebut bersama.
            //
            // Angka setara yang berdiri sendiri terlihat seperti kesalahan
            // hitung — 3 jam kok jadi 6. Menyebut "hari libur" di sebelahnya
            // menjelaskannya tanpa perlu dibuka.
            InfoRow(
              icon: Icons.calculate_outlined,
              text: '${formatHours(request.equivalentHours)} jam setara'
                  '${dayLabel.isEmpty ? '' : ' · $dayLabel'}',
            ),

            if (request.dayTypeReason?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(request.dayTypeReason!, style: AppText.caption),
            ],

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

            // Alasan penolakan ditampilkan paling menonjol. Ini yang pertama
            // dicari orang begitu laporannya ditolak — menyembunyikannya di
            // balik badge "Ditolak" berarti dia akan bertanya ke HR.
            if (request.approvalStatus == 'rejected') ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.dangerSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 15, color: AppColor.danger),
                        const SizedBox(width: 6),
                        Text(
                          'Alasan penolakan',
                          style:
                              AppText.label.copyWith(color: AppColor.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.decisionNote?.isNotEmpty == true
                          ? request.decisionNote!
                          : 'Tidak ada alasan yang dituliskan. Tanyakan '
                              'langsung ke ${request.decidedByName ?? 'atasan Anda'}.',
                      style: AppText.body.copyWith(color: AppColor.danger),
                    ),
                    if (request.decidedByName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Ditolak oleh ${request.decidedByName}',
                        style: AppText.label.copyWith(color: AppColor.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}