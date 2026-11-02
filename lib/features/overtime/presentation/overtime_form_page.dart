import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/overtime/cubit/overtime_form/overtime_form_cubit.dart';
import 'package:hris_mobile/features/overtime/cubit/overtime_form/overtime_form_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';

import '../model/overtime_model.dart';

class OvertimeFormPage extends StatefulWidget {
  const OvertimeFormPage({super.key});

  @override
  State<OvertimeFormPage> createState() => _OvertimeFormPageState();
}

class _OvertimeFormPageState extends State<OvertimeFormPage> {
  final _reasonController = TextEditingController();

  DateTime 
  
  
  _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  XFile? _proof;

  static final _dateFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime get _startAt => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _start.hour,
        _start.minute,
      );


  DateTime get _endAt {
    final end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end.hour,
      _end.minute,
    );

    return end.isAfter(_startAt)
        ? end
        : end.add(const Duration(days: 1));
  }

  bool get _crossesMidnight => _endAt.day != _startAt.day;

  void _refreshPreview() {
    context.read<OvertimeFormCubit>().preview(
          startAt: _startAt,
          endAt: _endAt,
        );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      
      firstDate: DateTime(now.year, now.month, now.day - 90),
      
      lastDate: now,
      helpText: 'Tanggal lembur',
    );

    if (picked == null) return;
    setState(() => _date = picked);
    _refreshPreview();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      helpText: isStart ? 'Mulai lembur' : 'Selesai lembur',
    );

    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
    _refreshPreview();
  }

  Future<void> _pickProof() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text('Lampirkan bukti', style: AppText.h2),
            ),
            // Galeri diizinkan. Bukti lembur sering berupa tangkapan layar
            // percakapan atau foto hasil kerja yang sudah ada di HP —
            // memaksa memotretnya ulang tidak masuk akal.
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Pilih dari galeri', style: AppText.body),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Ambil foto', style: AppText.body),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (file == null || !mounted) return;
      setState(() => _proof = file);
    } catch (e) {
      debugPrint('Gagal memilih bukti: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tidak bisa membuka galeri atau kamera. Periksa izinnya di '
            'pengaturan HP.',
          ),
          backgroundColor: AppColor.danger,
        ),
      );
    }
  }

  void _submit() {
    context.read<OvertimeFormCubit>().submit(
          startAt: _startAt,
          endAt: _endAt,
          reason: _reasonController.text,
          proofPath: _proof?.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporkan Lembur')),
      body: BlocConsumer<OvertimeFormCubit, OvertimeFormState>(
        listener: (context, state) {
          if (state is OvertimeFormSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is OvertimeFormSubmitError) {
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
          final busy = state is OvertimeFormSubmitting;
          final preview =
              state is OvertimeFormPreviewed ? state.preview : null;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('WAKTU LEMBUR', style: AppText.label),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: busy ? null : _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        suffixIcon: Icon(Icons.event, size: 20),
                      ),
                      child: Text(
                        _dateFormat.format(_date),
                        style: AppText.bodyStrong,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: busy ? null : () => _pickTime(isStart: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Mulai',
                              suffixIcon: Icon(Icons.schedule, size: 20),
                            ),
                            child: Text(
                              _start.format(context),
                              style: AppText.bodyStrong,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: busy ? null : () => _pickTime(isStart: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Selesai',
                              suffixIcon: Icon(Icons.schedule, size: 20),
                            ),
                            child: Text(
                              _end.format(context),
                              style: AppText.bodyStrong,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Disebutkan eksplisit, bukan dibiarkan disimpulkan sendiri.
                  //
                  // Orang yang mengisi 22:00 sampai 02:00 perlu tahu bahwa
                  // sistem membacanya sebagai empat jam melewati tengah
                  // malam — bukan sebagai kesalahan yang akan ditolak.
                  if (_crossesMidnight) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.nightlight_outlined,
                            size: 15, color: AppColor.info),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Melewati tengah malam, selesai '
                            '${_dateFormat.format(_endAt)}. Tarifnya mengikuti '
                            'hari mulai.',
                            style:
                                AppText.caption.copyWith(color: AppColor.info),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Pratinjau ditaruh sebelum kolom alasan.
                  //
                  // Orang perlu tahu jenis harinya dan jam setaranya SEBELUM
                  // menulis alasan — kalau tanggalnya ternyata salah, dia
                  // akan mengubahnya, dan alasan yang sudah ditulis jadi
                  // sia-sia.
                  if (state is OvertimeFormPreviewing)
                    const _PreviewLoading()
                  else if (state is OvertimeFormPreviewRejected)
                    _PreviewRejected(message: state.message)
                  else if (preview != null)
                    _PreviewCard(preview: preview)
                  else
                    const _PreviewEmpty(),

                  const Divider(height: 32),

                  TextField(
                    controller: _reasonController,
                    enabled: !busy,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Pekerjaan yang dikerjakan',
                      hintText: 'mis. Menyelesaikan laporan bulanan untuk '
                          'presentasi besok pagi',
                      alignLabelWithHint: true,
                      helperText: 'Atasan memutuskan berdasarkan ini. '
                          'Sebutkan pekerjaannya, bukan cuma "lembur".',
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text('BUKTI (WAJIB)', style: AppText.label),
                  const SizedBox(height: 8),

                  _ProofField(
                    file: _proof,
                    enabled: !busy,
                    onPick: _pickProof,
                    onRemove: () => setState(() => _proof = null),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'Sebagian perusahaan mewajibkan bukti. Kalau wajib dan '
                    'belum dilampirkan, laporannya ditolak saat dikirim.',
                    style: AppText.caption,
                  ),

                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: busy || preview == null ? null : _submit,
                    child: Text(
                      busy
                          ? (state).step
                          : 'Kirim Laporan',
                    ),
                  ),

                  if (preview == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Laporan baru bisa dikirim setelah jenis hari dan jam '
                      'setaranya dihitung.',
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

class _PreviewCard extends StatelessWidget {
  final OvertimePreviewData preview;

  const _PreviewCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final tiers = preview.tiers ?? [];
    final usedToday = preview.hoursUsedToday ?? 0;
    final usedWeek = preview.hoursUsedThisWeek ?? 0;

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
          Text('PERHITUNGAN', style: AppText.label),
          const SizedBox(height: 10),

          Row(
            children: [
              _PreviewStat(
                label: 'Durasi',
                value: '${formatHours(preview.hours)} jam',
              ),
              _PreviewStat(
                label: 'Jenis hari',
                value: preview.dayTypeLabel ??
                    kDayTypeLabels[preview.dayType] ??
                    '-',
              ),
              _PreviewStat(
                label: 'Setara',
                value: '${formatHours(preview.equivalentHours)} jam',
                highlight: true,
              ),
            ],
          ),

          // Alasan penggolongan hari disebutkan. Orang yang mengira Sabtu
          // biasa lalu melihat pengali hari libur akan curiga sistemnya
          // salah — kalimat ini yang mencegahnya.
          if (preview.dayTypeReason?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(preview.dayTypeReason!, style: AppText.caption),
          ],

          // Tingkatan pengali ditampilkan, bukan cuma hasil akhirnya.
          //
          // Angka setara yang berdiri sendiri terlihat seperti kesalahan
          // hitung — 3 jam kok jadi 6. Rinciannya membuat itu bisa diperiksa
          // sendiri tanpa bertanya ke HR.
          if (tiers.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...tiers.map(
              (tier) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tier.label ?? ''} — ${formatHours(tier.hours)} jam '
                        '× ${formatHours(tier.multiplier)}',
                        style: AppText.caption,
                      ),
                    ),
                    Text(
                      '${formatHours(tier.equivalentHours)} jam',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Batas yang tersisa disebut sebelum dikirim.
          //
          // Penolakan karena melebihi batas harian lebih baik dicegah
          // daripada dijelaskan — orang yang sudah menulis alasan lalu
          // ditolak harus mengulang seluruhnya.
          if (usedToday > 0 || usedWeek > 0) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (usedToday > 0)
                  'Sudah ${formatHours(usedToday)} jam hari ini',
                if (usedWeek > 0)
                  '${formatHours(usedWeek)} jam pekan ini',
              ].join(' · '),
              style: AppText.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PreviewStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.bodyStrong.copyWith(
              fontSize: 16,
              color: highlight ? AppColor.primary : AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColor.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _PreviewRejected extends StatelessWidget {
  final String message;

  const _PreviewRejected({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.dangerSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: AppColor.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.body.copyWith(color: AppColor.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewEmpty extends StatelessWidget {
  const _PreviewEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.border),
      ),
      child: Text(
        'Menghitung jenis hari dan jam setaranya...',
        textAlign: TextAlign.center,
        style: AppText.caption,
      ),
    );
  }
}

class _ProofField extends StatelessWidget {
  final XFile? file;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ProofField({
    required this.file,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return OutlinedButton.icon(
        onPressed: enabled ? onPick : null,
        icon: const Icon(Icons.attach_file, size: 20),
        label: const Text('Lampirkan Bukti'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file!.path),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? onPick : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Ganti'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.danger,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}