import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../cubit/shift_swap_cubit.dart';
import '../cubit/shift_swap_state.dart';
import '../model/shift_swap_model.dart';


class ShiftSwapFormPage extends StatefulWidget {
  final String employeeShiftId;

  final String myShiftName;
  final String myWorkDate;

  const ShiftSwapFormPage({
    super.key,
    required this.employeeShiftId,
    required this.myShiftName,
    required this.myWorkDate,
  });

  @override
  State<ShiftSwapFormPage> createState() => _ShiftSwapFormPageState();
}

class _ShiftSwapFormPageState extends State<ShiftSwapFormPage> {
  final _reasonController = TextEditingController();

  static final _dateFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    context.read<ShiftSwapCubit>().loadCandidates(widget.employeeShiftId);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _clock(String? iso) {
    if (iso == null) return '--:--';
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tukar Shift')),
      body: BlocConsumer<ShiftSwapCubit, ShiftSwapState>(
        listener: (context, state) {
          if (state is ShiftSwapSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is ShiftSwapError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.danger,
                  duration: const Duration(seconds: 6),
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is ShiftSwapInitial ||
              state is ShiftSwapLoadingCandidates) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShiftSwapNoCandidates) {
            return _NoCandidates(workDate: widget.myWorkDate);
          }

          if (state is ShiftSwapError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context
                  .read<ShiftSwapCubit>()
                  .loadCandidates(widget.employeeShiftId),
            );
          }

          final selected =
              state is ShiftSwapPreviewed ? state.selected : null;
          final preview =
              state is ShiftSwapPreviewed ? state.preview : null;

          final candidates = switch (state) {
            ShiftSwapCandidatesLoaded s => s.candidates,
            ShiftSwapPreviewed s => s.candidates,
            _ => <SwapCandidate>[],
          };

          final previewingId = state is ShiftSwapPreviewing
              ? state.candidateShiftId
              : null;

          final busy = state is ShiftSwapSubmitting;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MyShiftCard(
                    shiftName: widget.myShiftName,
                    workDate: widget.myWorkDate,
                    dateFormat: _dateFormat,
                  ),

                  const SizedBox(height: 20),

                  Text('TUKAR DENGAN', style: AppText.label),
                  const SizedBox(height: 4),
                  Text(
                    'Hanya rekan satu departemen yang shiftnya berbeda di '
                    'tanggal ini.',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 12),

                  ...candidates.map(
                    (candidate) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CandidateCard(
                        candidate: candidate,
                        selected: selected?.employeeShiftId ==
                            candidate.employeeShiftId,
                        loading:
                            previewingId == candidate.employeeShiftId,
                        onTap: busy
                            ? null
                            : () => context
                                .read<ShiftSwapCubit>()
                                .preview(candidate),
                        clock: _clock,
                      ),
                    ),
                  ),

                  if (preview != null) ...[
                    const SizedBox(height: 10),
                    _PreviewCard(
                      preview: preview,
                      myShiftName: widget.myShiftName,
                      selected: selected!,
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: _reasonController,
                      enabled: !busy,
                      maxLines: 2,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Alasan (opsional)',
                        hintText: 'mis. Ada urusan keluarga pagi itu',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FilledButton(
                      onPressed: busy || !preview.canSubmit
                          ? null
                          : () => context.read<ShiftSwapCubit>().submit(
                                candidate: selected,
                                reason: _reasonController.text,
                              ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        busy
                            ? 'Mengirim...'
                            : 'Ajukan ke ${selected.employeeName ?? 'rekan'}',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Disebutkan sebelum dikirim, bukan setelah.
                    //
                    // Orang yang tidak tahu rekannya harus setuju dulu akan
                    // mengira pengajuannya macet — padahal sedang menunggu
                    // di HP rekannya.
                    Text(
                      'Pengajuan dikirim ke ${selected.employeeName ?? 'rekan'} '
                      'dulu. Setelah dia setuju, baru diteruskan ke atasan.',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),

              if (busy)
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x33000000)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MyShiftCard extends StatelessWidget {
  final String shiftName;
  final String workDate;
  final DateFormat dateFormat;

  const _MyShiftCard({
    required this.shiftName,
    required this.workDate,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHIFT ANDA', style: AppText.label),
          const SizedBox(height: 6),
          Text(shiftName, style: AppText.h2),
          const SizedBox(height: 2),
          Text(
            dateFormat.format(DateTime.parse(workDate)),
            style: AppText.body,
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final SwapCandidate candidate;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;
  final String Function(String?) clock;

  const _CandidateCard({
    required this.candidate,
    required this.selected,
    required this.loading,
    required this.onTap,
    required this.clock,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColor.primarySurface : AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColor.primary : AppColor.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  selected ? AppColor.primary : AppColor.background,
              child: Text(
                (candidate.employeeName ?? '?')
                    .trim()
                    .characters
                    .first
                    .toUpperCase(),
                style: AppText.bodyStrong.copyWith(
                  color: selected ? Colors.white : AppColor.textSecondary,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.employeeName ?? '-',
                    style: AppText.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${candidate.shiftName ?? '-'} · '
                    '${clock(candidate.startAt)}–${clock(candidate.endAt)}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),

            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColor.primary : AppColor.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final SwapPreviewData preview;
  final String myShiftName;
  final SwapCandidate selected;

  const _PreviewCard({
    required this.preview,
    required this.myShiftName,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final blockers = preview.blockers ?? [];
    final warnings = preview.warnings ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SETELAH DITUKAR', style: AppText.label),
              const SizedBox(height: 10),

              // Ditulis sebagai kalimat, bukan tabel.
              //
              // Tabel dua kolom memaksa mata bolak-balik untuk menyimpulkan
              // sesuatu yang bisa dibaca sekali kalau ditulis begini.
              _Line(
                icon: Icons.person_outline,
                text: 'Anda masuk ${selected.shiftName ?? '-'}',
                strong: true,
              ),
              const SizedBox(height: 6),
              _Line(
                icon: Icons.people_outline,
                text: '${selected.employeeName ?? 'Rekan'} masuk $myShiftName',
              ),

              if (preview.swapType == 'cross_date') ...[
                const SizedBox(height: 6),
                _Line(
                  icon: Icons.swap_horiz,
                  text: 'Tanggalnya juga bertukar.',
                ),
              ],
            ],
          ),
        ),

        // Penghalang ditampilkan paling menonjol. Ini yang membuat tombol
        // kirim mati, dan orang perlu tahu kenapa — bukan cuma menemukan
        // tombolnya tidak bisa ditekan.
        if (blockers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.dangerSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.block, size: 16, color: AppColor.danger),
                    const SizedBox(width: 8),
                    Text(
                      'Tidak bisa ditukar',
                      style:
                          AppText.bodyStrong.copyWith(color: AppColor.danger),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...blockers.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      b,
                      style: AppText.body.copyWith(color: AppColor.danger),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Peringatan TIDAK menghalangi, dan itu disebutkan.
        //
        // Tanpa keterangan itu, orang yang melihat kotak kuning akan
        // mengira pengajuannya akan ditolak lalu mengurungkan niat.
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.warningSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColor.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Perlu diperhatikan',
                      style:
                          AppText.bodyStrong.copyWith(color: AppColor.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      w.message ?? '',
                      style: AppText.body.copyWith(color: AppColor.warning),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pengajuan tetap bisa dikirim. Atasan akan melihat catatan '
                  'ini juga.',
                  style: AppText.caption.copyWith(color: AppColor.warning),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool strong;

  const _Line({
    required this.icon,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColor.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: strong ? AppText.bodyStrong : AppText.body,
          ),
        ),
      ],
    );
  }
}

/// Tidak ada rekan yang bisa diajak.
///
/// Penjelasannya spesifik, bukan "tidak ada data". Layar kosong tanpa alasan
/// terlihat seperti kerusakan — dan orang akan mencoba berulang kali.
class _NoCandidates extends StatelessWidget {
  final String workDate;

  const _NoCandidates({required this.workDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz,
              size: 44, color: AppColor.textDisabled),
          const SizedBox(height: 16),
          Text(
            'Tidak ada rekan yang bisa diajak',
            style: AppText.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Tukar shift hanya bisa dengan rekan satu departemen yang '
            'shiftnya berbeda di tanggal ini.',
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KEMUNGKINAN PENYEBABNYA', style: AppText.label),
                const SizedBox(height: 8),
                Text(
                  'Rekan sedepartemen punya shift yang sama.\n'
                  'Mereka tidak dijadwalkan di tanggal ini.\n'
                  'Shiftnya sudah dipakai absensi.\n'
                  'Mereka sedang cuti.\n'
                  'Shiftnya sedang dalam proses tukar yang lain.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}