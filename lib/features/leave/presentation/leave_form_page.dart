import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../cubit/leave_form_cubit.dart';
import '../cubit/leave_form_state.dart';
import '../model/leave_model.dart';

/// Formulir pengajuan cuti.
///
/// Pratinjau dihitung ulang setiap kali jenis atau tanggal berubah, bukan saat
/// tombol kirim ditekan. Angka yang muncul setelah pengajuan terkirim sudah
/// terlambat untuk berguna — yang dibutuhkan orang adalah melihat "3 hari
/// kerja, sisa jatah jadi 5" sebelum memutuskan.
class LeaveFormPage extends StatefulWidget {
  final List<LeaveTypeData> types;

  const LeaveFormPage({super.key, required this.types});

  @override
  State<LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final _reasonController = TextEditingController();
  final _contactController = TextEditingController();

  LeaveTypeData? _type;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _halfDay = false;
  XFile? _attachment;

  static final _apiFormat = DateFormat('yyyy-MM-dd');
  // static final _displayFormat = DateFormat('EEE, d MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _type = widget.types.isNotEmpty ? widget.types.first : null;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  bool get _canPreview =>
      _type?.id != null && _startDate != null && _endDate != null;

  /// Setengah hari hanya sah kalau tanggalnya satu — backend menolak yang
  /// lain. Diperiksa di sini juga supaya sakelarnya tidak bisa dinyalakan
  /// untuk rentang, alih-alih dinyalakan lalu ditolak.
  bool get _halfDayAllowed =>
      _startDate != null &&
      _endDate != null &&
      _apiFormat.format(_startDate!) == _apiFormat.format(_endDate!);

  void _refreshPreview() {
    if (!_canPreview) return;

    context.read<LeaveFormCubit>().preview(
          leaveTypeId: _type!.id!,
          startDate: _apiFormat.format(_startDate!),
          endDate: _apiFormat.format(_endDate!),
          halfDay: _halfDay,
        );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startDate : _endDate) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // Mundur 90 hari diizinkan karena cuti sakit sering diajukan setelah
      // kejadian — orang yang sakit tiga hari tidak mengajukan dari kasur.
      firstDate: DateTime(now.year, now.month, now.day - 90),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: isStart ? 'Mulai cuti' : 'Selesai cuti',
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // Tanggal selesai ikut maju kalau jadi lebih awal dari mulai.
        // Membiarkannya tidak sah lalu ditolak backend berarti orang harus
        // menebak mana yang salah.
        if (_endDate == null || _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
        if (_startDate == null || _startDate!.isAfter(picked)) {
          _startDate = picked;
        }
      }

      if (!_halfDayAllowed) _halfDay = false;
    });

    _refreshPreview();
  }

  /// Lampiran wajib untuk jenis tertentu — biasanya cuti sakit lebih dari
  /// sehari, yang butuh surat dokter.
  ///
  /// Diperiksa di sini juga supaya orang tidak mengisi formulir lengkap lalu
  /// ditolak backend di akhir.
  bool get _attachmentRequired => _type?.requiresAttachment == true;

  bool get _canSubmit =>
      _canPreview && (!_attachmentRequired || _attachment != null);

  Future<void> _pickAttachment() async {
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
              child: Text('Lampirkan dokumen', style: AppText.h2),
            ),
            // Galeri diizinkan di sini, berbeda dari swafoto absensi.
            //
            // Surat dokter sering sudah difoto atau dikirim lewat WhatsApp
            // sebelumnya — memaksa memotretnya ulang di tempat berarti
            // menyuruh orang sakit mencari kertasnya lagi.
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

      if (file == null) return;
      setState(() => _attachment = file);
    } catch (e) {
      // Kamera dan galeri bisa gagal karena izin ditolak atau plugin belum
      // termuat. Tanpa penangkapan ini errornya lolos sebagai Unhandled
      // Exception, dan layarnya cuma diam.
      debugPrint('Gagal memilih lampiran: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tidak bisa membuka galeri atau kamera. Periksa izinnya di '
            'pengaturan HP, lalu coba lagi.',
          ),
          backgroundColor: AppColor.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _submit() {
    context.read<LeaveFormCubit>().submit(
          leaveTypeId: _type!.id!,
          startDate: _apiFormat.format(_startDate!),
          endDate: _apiFormat.format(_endDate!),
          halfDay: _halfDay,
          reason: _reasonController.text,
          attachmentPath: _attachment?.path,
          contactDuringLeave: _contactController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Cuti')),
      body: BlocConsumer<LeaveFormCubit, LeaveFormState>(
        listener: (context, state) {
          if (state is LeaveFormSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is LeaveFormSubmitError) {
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
          final busy = state is LeaveFormSubmitting;
          final preview = state is LeaveFormPreviewed ? state.preview : null;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('JENIS CUTI', style: AppText.label),
                  const SizedBox(height: 10),

                  ...widget.types.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TypeCard(
                        type: type,
                        selected: _type?.id == type.id,
                        onTap: busy
                            ? null
                            : () {
                                setState(() => _type = type);
                                _refreshPreview();
                              },
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  Text('TANGGAL', style: AppText.label),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Mulai',
                          value: _startDate,
                          enabled: !busy,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Selesai',
                          value: _endDate,
                          enabled: !busy,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),

                  if (_halfDayAllowed) ...[
                    const SizedBox(height: 4),
                    SwitchListTile(
                      value: _halfDay,
                      onChanged: busy
                          ? null
                          : (value) {
                              setState(() => _halfDay = value);
                              _refreshPreview();
                            },
                      title: Text('Setengah hari', style: AppText.body),
                      subtitle: Text(
                        'Memotong 0,5 hari dari jatah, bukan 1 hari.',
                        style: AppText.caption,
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Pratinjau ditaruh sebelum kolom alasan, bukan di dekat
                  // tombol kirim.
                  //
                  // Orang perlu tahu berapa hari yang terpotong SEBELUM
                  // memutuskan menulis alasan — kalau ternyata jatahnya tidak
                  // cukup, dia akan mengubah tanggalnya, dan alasan yang sudah
                  // ditulis jadi sia-sia.
                  if (state is LeaveFormPreviewing)
                    const _PreviewLoading()
                  else if (state is LeaveFormPreviewRejected)
                    _PreviewRejected(message: state.message)
                  else if (preview != null)
                    _PreviewCard(preview: preview)
                  else
                    _PreviewEmpty(canPreview: _canPreview),

                  const Divider(height: 32),

                  TextField(
                    controller: _reasonController,
                    enabled: !busy,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Alasan',
                      hintText: 'mis. Acara keluarga di luar kota',
                      alignLabelWithHint: true,
                    ),
                  ),

                  TextField(
                    controller: _contactController,
                    enabled: !busy,
                    maxLength: 40,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor yang bisa dihubungi (opsional)',
                      helperText:
                          'Diisi kalau ada yang perlu menghubungi Anda selama cuti.',
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        _attachmentRequired
                            ? 'LAMPIRAN (WAJIB)'
                            : 'LAMPIRAN (OPSIONAL)',
                        style: AppText.label.copyWith(
                          color: _attachmentRequired && _attachment == null
                              ? AppColor.danger
                              : AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _AttachmentField(
                    file: _attachment,
                    enabled: !busy,
                    onPick: _pickAttachment,
                    onRemove: () => setState(() => _attachment = null),
                  ),

                  if (_attachmentRequired && _attachment == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_type?.name ?? 'Jenis ini'} wajib melampirkan dokumen '
                      'pendukung — biasanya surat dokter.',
                      style: AppText.caption.copyWith(color: AppColor.danger),
                    ),
                  ],

                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed:
                        busy || preview == null || !_canSubmit ? null : _submit,
                    child: Text(
                      busy
                          ? (state).step
                          : 'Kirim Pengajuan',
                    ),
                  ),

                  if (preview == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pilih jenis dan tanggal dulu — pengajuan baru bisa '
                      'dikirim setelah dampaknya dihitung.',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ],

                  const SizedBox(height: 16),

                  Text(
                    'Saldo dipotong sejak pengajuan dikirim, bukan setelah '
                    'disetujui — supaya tidak ada dua pengajuan yang sama-sama '
                    'lolos pemeriksaan jatah. Kalau ditolak, potongannya '
                    'dikembalikan otomatis.',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),

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

class _TypeCard extends StatelessWidget {
  final LeaveTypeData type;
  final bool selected;
  final VoidCallback? onTap;

  const _TypeCard({
    required this.type,
    required this.selected,
    this.onTap,
  });

  /// Keterangan yang menjelaskan akibatnya, bukan mengulang namanya.
  String get _description {
    final parts = <String>[];

    if (type.deductsQuota == false) {
      parts.add('Tidak memotong jatah tahunan');
    }
    if (type.isPaid == false) {
      parts.add('Tidak dibayar');
    }
    if (type.maxDaysPerEvent != null) {
      parts.add('Maksimal ${formatDays(type.maxDaysPerEvent)} hari per kejadian');
    }
    if (type.requiresAttachment == true) {
      parts.add('Wajib lampiran');
    }

    return parts.isEmpty ? 'Memotong jatah cuti tahunan' : parts.join(' · ');
  }

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
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColor.primary : AppColor.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.name ?? '-',
                          style: AppText.bodyStrong.copyWith(
                            color: selected
                                ? AppColor.primary
                                : AppColor.textPrimary,
                          ),
                        ),
                      ),
                      if (type.category != null)
                        Text(
                          LeaveCategories.labels[type.category] ?? '',
                          style: AppText.label,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(_description, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  static final _format = DateFormat('d MMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.event, size: 20),
          enabled: enabled,
        ),
        child: Text(
          value == null ? 'Pilih' : _format.format(value!),
          style: value == null
              ? AppText.body.copyWith(color: AppColor.textDisabled)
              : AppText.bodyStrong,
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final LeavePreviewData preview;

  const _PreviewCard({required this.preview});

  static final _skipFormat = DateFormat('d MMM', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final unpaid = preview.unpaidDays ?? 0;

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
          Text('DAMPAK PENGAJUAN', style: AppText.label),
          const SizedBox(height: 10),

          Row(
            children: [
              _PreviewStat(
                label: 'Hari kerja',
                value: formatDays(preview.workingDays),
              ),
              _PreviewStat(
                label: 'Sisa jatah',
                value: formatDays(preview.balanceBefore),
              ),
              _PreviewStat(
                label: 'Jadi',
                value: formatDays(preview.balanceAfter),
                highlight: true,
              ),
            ],
          ),

          if (unpaid > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.warningSurface,
                borderRadius: BorderRadius.circular(8),
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
                      '${formatDays(unpaid)} hari melebihi sisa jatah dan akan '
                      'tercatat sebagai cuti tidak dibayar.',
                      style: AppText.caption.copyWith(color: AppColor.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tanggal yang dilewati disebutkan, bukan cuma dikurangi diam-diam.
          //
          // Orang yang mengajukan 5 hari lalu melihat "3 hari kerja" akan
          // bertanya kenapa. Menyebutkan hari liburnya menjawab pertanyaan itu
          // sebelum ditanyakan.
          if (preview.skipped?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              'Tidak dihitung: ${preview.skipped!.map((s) => '${_skipFormat.format(DateTime.parse(s.date!))} (${s.reason})').join(', ')}',
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
            style: AppText.h1.copyWith(
              fontSize: 22,
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
          const Icon(Icons.error_outline, size: 18, color: AppColor.danger),
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
  final bool canPreview;

  const _PreviewEmpty({required this.canPreview});

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
        canPreview
            ? 'Menghitung dampaknya...'
            : 'Pilih tanggal untuk melihat berapa hari kerja yang terpotong.',
        textAlign: TextAlign.center,
        style: AppText.caption,
      ),
    );
  }
}

class _AttachmentField extends StatelessWidget {
  final XFile? file;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _AttachmentField({
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
        label: const Text('Pilih Dokumen'),
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