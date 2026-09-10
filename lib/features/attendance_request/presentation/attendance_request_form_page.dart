import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/attendance-history/model/attendance_history_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
// Diberi prefiks karena attendance_history_model dan attendance_request_model
// sama-sama punya kelas bernama Data — json_to_dart selalu menamai kelas
// bersarangnya begitu. Tanpa prefiks, Data di berkas ini menunjuk ke model
// yang salah, dan errornya muncul sebagai "getter tidak ditemukan" alih-alih
// sebagai tabrakan nama.
import '../cubit/attendance_request_cubit.dart';
import '../cubit/attendance_request_state.dart';
import '../model/create_attendance_request_model.dart';

/// Formulir koreksi absensi untuk satu shift tertentu.
///
/// Diluncurkan dari kartu riwayat, bukan dari menu kosong. Karyawan sudah
/// menunjuk hari yang bermasalah — menyuruhnya memilih ulang shift dari
/// dropdown berarti melupakan yang baru saja dia katakan.
class AttendanceRequestFormPage extends StatefulWidget {
  /// Baris riwayat yang bermasalah. Dari sini formulir tahu shift mana yang
  /// dimaksud, jam jadwalnya, dan apakah catatan masuknya sudah ada.
  final AttendanceHistoryData row;

  const AttendanceRequestFormPage({super.key, required this.row});

  @override
  State<AttendanceRequestFormPage> createState() =>
      _AttendanceRequestFormPageState();
}

class _AttendanceRequestFormPageState extends State<AttendanceRequestFormPage> {
  final _reasonController = TextEditingController();

  late String _type;
  DateTime? _clockInAt;
  DateTime? _clockOutAt;
  XFile? _selfie;
  DateTime? _photoTakenAt;

  static final _dayFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm');

  /// Jenis yang masuk akal untuk baris ini.
  ///
  /// Kalau catatan masuknya sudah ada, satu-satunya yang mungkin adalah lupa
  /// clock out — backend menolak jam masuk kedua dengan ConflictException.
  /// Menampilkan pilihan yang pasti ditolak berarti membiarkan orang mengisi
  /// formulir lengkap untuk sesuatu yang tidak akan pernah diterima.
  List<String> get _allowedTypes {
    final hasClockIn = widget.row.clockInAt != null;

    if (hasClockIn) return [AttendanceRequestTypes.forgotClockOut];

    return [
      AttendanceRequestTypes.forgotClockIn,
      AttendanceRequestTypes.wfh,
      AttendanceRequestTypes.businessTrip,
    ];
  }

  bool get _needsClockIn => _type != AttendanceRequestTypes.forgotClockOut;
  bool get _needsClockOut => _type == AttendanceRequestTypes.forgotClockOut;

  @override
  void initState() {
    super.initState();
    _type = _allowedTypes.first;
    _prefillTimes();
  }

  /// Jam diisi dari JADWAL shift, bukan dibiarkan kosong.
  ///
  /// Jam jadwal adalah jawaban yang paling mungkin benar, dan pasti lolos
  /// pemeriksaan penyimpangan 12 jam di backend. Formulir kosong memaksa orang
  /// mengetik tanggal dan jam dari nol lewat pemilih waktu — dan itu tempat
  /// paling gampang salah pilih tanggal.
  void _prefillTimes() {
    final start = widget.row.scheduledStart;
    final end = widget.row.scheduledEnd;

    if (start != null) _clockInAt = DateTime.parse(start).toLocal();
    if (end != null) _clockOutAt = DateTime.parse(end).toLocal();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();

    // Kamera, bukan galeri. Swafoto yang bisa dipilih dari galeri kehilangan
    // seluruh gunanya sebagai bukti — dan itu satu-satunya alasan swafotonya
    // diminta.
    final file = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
      maxWidth: 1080,
    );

    if (file == null) return;

    setState(() {
      _selfie = file;
      _photoTakenAt = DateTime.now();
    });
  }

  Future<void> _pickTime({required bool isClockIn}) async {
    final initial = isClockIn ? _clockInAt : _clockOutAt;
    final base = initial ?? DateTime.now();

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: isClockIn ? 'Jam masuk sebenarnya' : 'Jam pulang sebenarnya',
    );

    if (time == null) return;

    // Tanggalnya diambil dari jam jadwal yang sudah terisi, bukan dari hari
    // ini. Yang dipilih orang cuma jamnya — dan mengganti tanggalnya secara
    // diam-diam adalah cara tercepat menghasilkan pengajuan yang ditolak
    // karena menyimpang lebih dari 12 jam.
    final result = DateTime(
      base.year,
      base.month,
      base.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isClockIn) {
        _clockInAt = result;
      } else {
        _clockOutAt = result;
      }
    });
  }

  void _submit() {
    context.read<AttendanceRequestCubit>().submit(
          employeeShiftId: widget.row.employeeShiftId!,
          type: _type,
          proposedClockInAt:
              _needsClockIn ? _clockInAt?.toUtc().toIso8601String() : null,
          proposedClockOutAt:
              _clockOutAt != null && (_needsClockOut || _needsClockIn)
                  ? _clockOutAt!.toUtc().toIso8601String()
                  : null,
          reason: _reasonController.text,
          selfiePath: _selfie!.path,
          photoTakenAt: _photoTakenAt,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Koreksi')),
      body: BlocConsumer<AttendanceRequestCubit, AttendanceRequestState>(
        listener: (context, state) {
          if (state is AttendanceRequestSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is AttendanceRequestSubmitError) {
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
          final busy = state is AttendanceRequestSubmitting;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ShiftHeader(row: widget.row),
                  const SizedBox(height: 20),

                  Text('JENIS PENGAJUAN', style: AppText.label),
                  const SizedBox(height: 10),

                  // Kartu yang bisa diketuk seluruh bidangnya, bukan radio
                  // kecil di ujung kiri. Target sentuh selebar layar jauh lebih
                  // mudah dikenai sambil berjalan — dan formulir ini memang
                  // sering diisi di jalan.
                  ..._allowedTypes.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TypeCard(
                        label: AttendanceRequestTypes.labels[type] ?? type,
                        description:
                            AttendanceRequestTypes.descriptions[type] ?? '',
                        selected: _type == type,
                        onTap: busy ? null : () => setState(() => _type = type),
                      ),
                    ),
                  ),

                  if (_allowedTypes.length == 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Catatan absen masuk untuk shift ini sudah ada, jadi yang '
                      'bisa diajukan hanya jam pulangnya. Kalau jam masuknya '
                      'yang salah, minta HR mengoreksinya langsung.',
                      style: AppText.caption,
                    ),
                  ],

                  const Divider(height: 32),

                  if (_needsClockIn)
                    _TimeField(
                      label: 'Jam masuk sebenarnya',
                      value: _clockInAt,
                      enabled: !busy,
                      onTap: () => _pickTime(isClockIn: true),
                    ),

                  if (_needsClockIn) const SizedBox(height: 12),

                  _TimeField(
                    label: _needsClockOut
                        ? 'Jam pulang sebenarnya'
                        : 'Jam pulang (opsional)',
                    value: _clockOutAt,
                    enabled: !busy,
                    onTap: () => _pickTime(isClockIn: false),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Sudah diisi sesuai jadwal shift. Ubah kalau jam '
                    'sebenarnya berbeda.',
                    style: AppText.caption,
                  ),

                  const Divider(height: 32),

                  TextField(
                    controller: _reasonController,
                    enabled: !busy,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Alasan',
                      hintText:
                          'mis. HP mati saat sampai kantor, dan baru bisa dicas siang',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 8),

                  _SelfieField(
                    selfie: _selfie,
                    enabled: !busy,
                    onTap: _pickSelfie,
                  ),

                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: busy || _selfie == null ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      busy
                          ? (state).step
                          : 'Kirim Pengajuan',
                    ),
                  ),

                  if (_selfie == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Swafoto wajib dilampirkan sebelum bisa dikirim.',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                  ],

                  const SizedBox(height: 16),

                  Text(
                    'Pengajuan diteruskan ke atasan langsung Anda, lalu ke HR. '
                    'Absensi baru berubah setelah keduanya menyetujui.',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),

                  const SizedBox(height: 32),
                ],
              ),

              // Penutup layar selama mengirim. Formulir yang masih bisa
              // disentuh saat unggahan berjalan mengundang ketukan kedua, dan
              // ketukan kedua menghasilkan pengajuan kembar.
              if (busy)
                const Positioned.fill(
                  child: ColoredBox(color: Color(0x22000000)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ShiftHeader extends StatelessWidget {
  final AttendanceHistoryData row;

  const _ShiftHeader({required this.row});

  @override
  Widget build(BuildContext context) {
    final date = row.workDate == null
        ? '-'
        : _AttendanceRequestFormPageState._dayFormat
            .format(DateTime.parse(row.workDate!).toLocal());

    String time(String? iso) => iso == null
        ? '--:--'
        : _AttendanceRequestFormPageState._timeFormat
            .format(DateTime.parse(iso).toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SHIFT YANG DIKOREKSI', style: AppText.label),
            const SizedBox(height: 6),
            Text(date, style: AppText.bodyStrong),
            const SizedBox(height: 4),
            Text(
              '${row.shiftName ?? 'Shift'} · '
              '${time(row.scheduledStart)} – ${time(row.scheduledEnd)}',
              style: AppText.body,
            ),
            if (row.clockInAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tercatat masuk ${time(row.clockInAt)}, '
                '${row.clockOutAt == null ? 'belum ada catatan pulang' : 'pulang ${time(row.clockOutAt)}'}',
                style: AppText.caption,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Tidak ada catatan absensi untuk shift ini',
                style: AppText.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
          enabled: enabled,
        ),
        child: Text(
          value == null
              ? '--:--'
              : _AttendanceRequestFormPageState._timeFormat.format(value!),
          style: AppText.bodyStrong,
        ),
      ),
    );
  }
}

class _SelfieField extends StatelessWidget {
  final XFile? selfie;
  final bool enabled;
  final VoidCallback onTap;

  const _SelfieField({
    required this.selfie,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selfie == null) {
      return OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Ambil Swafoto'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(selfie!.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: const Icon(Icons.refresh),
          label: const Text('Ambil Ulang'),
        ),
      ],
    );
  }
}

/// Kartu pilihan jenis pengajuan.
///
/// Menggantikan RadioListTile: seluruh bidangnya bisa diketuk, dan yang
/// terpilih ditandai warna latar plus garis tepi — bukan cuma titik kecil di
/// ujung kiri yang mudah terlewat.
class _TypeCard extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  const _TypeCard({
    required this.label,
    required this.description,
    required this.selected,
    this.onTap,
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
                  Text(
                    label,
                    style: AppText.bodyStrong.copyWith(
                      color: selected ? AppColor.primary : AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}