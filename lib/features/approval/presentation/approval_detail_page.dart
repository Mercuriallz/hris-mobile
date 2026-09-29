import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:hris_mobile/features/approval/cubit/approval_detail_cubit.dart';
import 'package:hris_mobile/features/approval/cubit/approval_detail_state.dart';
import 'package:hris_mobile/features/approval/model/approval_detail_model.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../cubit/approval_cubit.dart';

import '../cubit/approval_state.dart';

class ApprovalDetailPage extends StatefulWidget {
  final String approvalId;

  const ApprovalDetailPage({super.key, required this.approvalId});

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ApprovalDetailCubit>().fetchDetail(widget.approvalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: BlocListener<ApprovalCubit, ApprovalState>(
        listener: (context, state) {
          if (state is ApprovalDecided) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            Navigator.pop(context, true);
          }
          if (state is ApprovalDecideError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.danger,
                  duration: const Duration(seconds: 5),
                ),
              );
          }
        },
        child: BlocBuilder<ApprovalDetailCubit, ApprovalDetailState>(
          builder: (context, state) {
            if (state is ApprovalDetailLoading ||
                state is ApprovalDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ApprovalDetailError) {
              return ErrorState(
                message: state.message,
                onRetry: () => context.read<ApprovalDetailCubit>().fetchDetail(
                  widget.approvalId,
                ),
              );
            }

            final loaded = state as ApprovalDetailLoaded;
            return _DetailBody(
              approval: loaded.approval,
              detail: loaded.detail,
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ApprovalSummary approval;
  final ApprovalDetail detail;

  const _DetailBody({required this.approval, required this.detail});

  bool get _isPending =>
      approval.status == 'pending' || approval.status == null;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalCubit, ApprovalState>(
      buildWhen: (previous, current) => current is ApprovalDeciding,
      builder: (context, approvalState) {
        final isDeciding =
            approvalState is ApprovalDeciding &&
            approvalState.approvalId == approval.id;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                
                  if (detail.photoUrl != null)
                    _PhotoCard(
                      url: detail.photoUrl!,
                      label: detail.photoLabel ?? 'Bukti',
                    )
                  else if (detail.photoLabel != null)
                    _NoPhotoCard(label: detail.photoLabel!),

                  if (detail.photoUrl != null || detail.photoLabel != null)
                    const SizedBox(height: 16),

                  _RequesterCard(
                    approval: approval,
                    title: detail.title ?? approval.summary ?? '-',
                  ),

                  const SizedBox(height: 16),

                  if (detail.fields?.isNotEmpty ?? false) ...[
                    Text('RINCIAN', style: AppText.label),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < detail.fields!.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _FieldRow(field: detail.fields![i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (detail.note?.isNotEmpty ?? false) ...[
                    Text('ALASAN PENGAJU', style: AppText.label),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(detail.note!, style: AppText.body),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (approval.steps?.isNotEmpty ?? false) ...[
                    Text('RANTAI PERSETUJUAN', style: AppText.label),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: approval.steps!
                              .map(
                                (step) => _StepRow(
                                  step: step,
                                  isCurrent:
                                      step.stepOrder == approval.currentStep,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),

            if (_isPending)
              _DecisionBar(
                approvalId: approval.id!,
                requesterName: approval.requester?.fullName ?? 'Karyawan',
                summary: detail.title ?? approval.summary ?? '',
                isDeciding: isDeciding,
              ),
          ],
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String url;
  final String label;

  const _PhotoCard({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.label),
        const SizedBox(height: 8),
        GestureDetector(
     
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullPhotoPage(url: url, label: label),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                height: 260,
                color: AppColor.background,
                child: const Center(child: CircularProgressIndicator()),
              ),

              errorWidget: (_, _, _) => Container(
                height: 260,
                color: AppColor.dangerSurface,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: AppColor.danger,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Foto gagal dimuat. Tautannya mungkin sudah '
                          'kedaluwarsa — tarik ke bawah untuk memuat ulang.',
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(
                            color: AppColor.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoPhotoCard extends StatelessWidget {
  final String label;

  const _NoPhotoCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.warningSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.no_photography_outlined,
            size: 20,
            color: AppColor.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label tidak tersedia. Pertimbangkan menanyakan langsung ke '
              'pengaju sebelum memutuskan.',
              style: AppText.caption.copyWith(color: AppColor.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullPhotoPage extends StatelessWidget {
  final String url;
  final String label;

  const _FullPhotoPage({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label, style: AppText.h2.copyWith(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _RequesterCard extends StatelessWidget {
  final ApprovalSummary approval;
  final String title;

  const _RequesterCard({required this.approval, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColor.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (approval.requester?.fullName?.isNotEmpty ?? false)
                      ? approval.requester!.fullName![0].toUpperCase()
                      : '?',
                  style: AppText.h2.copyWith(color: AppColor.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    approval.requester?.fullName ?? 'Karyawan',
                    style: AppText.bodyStrong,
                  ),
                  Text(
                    approval.requester?.employeeNumber ?? '',
                    style: AppText.label,
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final DetailField field;

  const _FieldRow({required this.field});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(field.label ?? '', style: AppText.caption),
          ),
          Expanded(child: Text(field.value ?? '—', style: AppText.bodyStrong)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final DetailStep step;
  final bool isCurrent;

  String get _roleLabel {
    switch (step.approverRole) {
      case 'hr':
        return 'HR';
      case 'line_manager':
        return 'Atasan langsung';
      case 'counterpart':
        return 'Rekan tukar shift';
      default:
        return 'Penyetuju';
    }
  }

  const _StepRow({required this.step, required this.isCurrent});

  static final _dateFormat = DateFormat('d MMM, HH:mm', 'id_ID');

  ({Color color, IconData icon}) get _visual {
    switch (step.status) {
      case 'approved':
        return (color: AppColor.success, icon: Icons.check_circle);
      case 'rejected':
        return (color: AppColor.danger, icon: Icons.cancel);
      case 'skipped':
        return (
          color: AppColor.textDisabled,
          icon: Icons.remove_circle_outline,
        );
      default:
        return isCurrent
            ? (color: AppColor.warning, icon: Icons.radio_button_checked)
            : (
                color: AppColor.textDisabled,
                icon: Icons.radio_button_unchecked,
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visual;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(visual.icon, size: 18, color: visual.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Langkah HR tidak menunjuk orang, jadi namanya null. Yang
                // ditampilkan perannya — tanpa ini barisnya terbaca
                // "Penyetuju" di atas "HR", dua kata untuk satu keterangan.
                Text(
                  step.approverNameSnapshot ?? _roleLabel,
                  style: AppText.body.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                Text(
                  [
                    _roleLabel,
                    if (step.decidedAt != null)
                      _dateFormat.format(
                        DateTime.parse(step.decidedAt!).toLocal(),
                      ),
                    if (isCurrent && step.decidedAt == null) 'menunggu',
                  ].join(' · '),
                  style: AppText.label,
                ),

                // Catatan keputusan ditampilkan di rantainya, bukan cuma di
                // kartu daftar. Penyetuju lapis kedua perlu tahu apa yang
                // dituliskan lapis pertama — kalau tidak, dia memutuskan tanpa
                // konteks yang sudah ada.
                if (step.note?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.note!,
                    style: AppText.caption.copyWith(color: visual.color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionBar extends StatelessWidget {
  final String approvalId;
  final String requesterName;
  final String summary;
  final bool isDeciding;

  const _DecisionBar({
    required this.approvalId,
    required this.requesterName,
    required this.summary,
    required this.isDeciding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isDeciding ? null : () => _reject(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.danger,
                  side: const BorderSide(color: AppColor.danger),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Tolak'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isDeciding ? null : () => _approve(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.success,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: isDeciding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Setujui'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final cubit = context.read<ApprovalCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui pengajuan?'),
        content: Text('$requesterName\n\n$summary', style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColor.success),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    cubit.decide(approvalId: approvalId, approve: true);
  }

  Future<void> _reject(BuildContext context) async {
    final cubit = context.read<ApprovalCubit>();
    final controller = TextEditingController();

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tolak pengajuan', style: AppText.h2),
            const SizedBox(height: 4),
            Text(
              'Alasan wajib diisi. $requesterName akan melihatnya di '
              'aplikasinya.',
              style: AppText.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText:
                    'mis. Jam yang diusulkan tidak cocok dengan catatan satpam',
              ),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: FilledButton.styleFrom(backgroundColor: AppColor.danger),
              child: const Text('Tolak Pengajuan'),
            ),
          ],
        ),
      ),
    );

    if (note == null || note.trim().isEmpty) return;
    cubit.decide(approvalId: approvalId, approve: false, note: note);
  }
}