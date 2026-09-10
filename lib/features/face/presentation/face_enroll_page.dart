import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../helper/face_embedding_service.dart';
import '../cubit/face_enroll_cubit.dart';
import '../cubit/face_enroll_state.dart';
import 'face_scan_page.dart';

/// Pendaftaran wajah untuk verifikasi absensi.
///
/// Dua langkah: baca penjelasan lalu setuju, baru ambil foto. Persetujuan
/// tidak boleh tersirat dari fakta bahwa seseorang menekan tombol kamera —
/// data biometrik butuh izin yang tercatat menurut UU PDP 27/2022, dan izin
/// yang diberikan tanpa tahu apa yang disimpan bukan izin.
class FaceEnrollPage extends StatefulWidget {
  const FaceEnrollPage({super.key});

  @override
  State<FaceEnrollPage> createState() => _FaceEnrollPageState();
}

class _FaceEnrollPageState extends State<FaceEnrollPage> {
  bool _consented = false;

  @override
  void initState() {
    super.initState();
    context.read<FaceEnrollCubit>().fetchStatus();
  }

  /// Memindai dengan kamera langsung, bukan ImagePicker.
  ///
  /// Bedanya bukan kerapian: pemindai memberi arahan SEBELUM fotonya diambil
  /// — dekatkan wajah, buka mata, hanya Anda di bingkai. ImagePicker cuma
  /// bisa menolak setelahnya, dan orang yang ditolak tiga kali tanpa tahu
  /// kenapa akan menyerah.
  Future<void> _takePhoto() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceScanPage(
          title: 'Daftarkan Wajah',
          instruction: 'Posisikan wajah di dalam bingkai',
        ),
      ),
    );

    if (path == null || !mounted) return;
    context.read<FaceEnrollCubit>().enroll(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftarkan Wajah')),
      body: BlocConsumer<FaceEnrollCubit, FaceEnrollState>(
        listener: (context, state) {
          if (state is FaceEnrollSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is FaceEnrollPhotoError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColor.warning,
                  duration: const Duration(seconds: 6),
                ),
              );
          }

          if (state is FaceEnrollError) {
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
          if (state is FaceEnrollLoading || state is FaceEnrollInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final busy = state is FaceEnrollProcessing;
          final status =
              state is FaceEnrollStatusLoaded ? state.status : null;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (status != null) _StatusCard(status: status),

                  const SizedBox(height: 20),

                  Text('YANG DISIMPAN', style: AppText.label),
                  const SizedBox(height: 10),

                  // Penjelasannya soal APA yang disimpan, bukan soal
                  // manfaatnya. Persetujuan yang diberikan tanpa tahu apa yang
                  // disimpan bukan persetujuan — dan "untuk keamanan absensi"
                  // tidak memberi tahu apa pun.
                  const _Point(
                    icon: Icons.calculate_outlined,
                    text: 'Yang disimpan bukan foto, melainkan deret angka '
                        'hasil perhitungan bentuk wajah Anda. Angka itu tidak '
                        'bisa dibalik menjadi foto.',
                  ),
                  const _Point(
                    icon: Icons.phone_android,
                    text: 'Fotonya diproses di HP ini lalu dihapus. Foto tidak '
                        'pernah dikirim ke server dan tidak disimpan di mana '
                        'pun.',
                  ),
                  const _Point(
                    icon: Icons.fact_check_outlined,
                    text: 'Angka itu dipakai memastikan yang absen memang '
                        'Anda, bukan rekan yang memegang HP Anda.',
                  ),
                  const _Point(
                    icon: Icons.gavel_outlined,
                    text: 'Data wajah termasuk data pribadi spesifik menurut '
                        'UU Perlindungan Data Pribadi. Anda berhak menolak, '
                        'dan absensi tetap bisa dilakukan tanpa ini.',
                  ),

                  const SizedBox(height: 8),
                  const Divider(),

                  CheckboxListTile(
                    value: _consented,
                    onChanged: busy
                        ? null
                        : (value) =>
                            setState(() => _consented = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Saya membaca penjelasan di atas dan setuju data wajah '
                      'saya disimpan untuk verifikasi absensi.',
                      style: AppText.body,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text('AGAR PENCOCOKAN BERHASIL', style: AppText.label),
                  const SizedBox(height: 8),
                  Text(
                    'Wajah menghadap kamera, cahaya rata, tanpa masker atau '
                    'kacamata gelap. Ambil di tempat yang mirip dengan tempat '
                    'Anda biasa absen — wajah yang didaftarkan di ruang terang '
                    'lalu diperiksa di parkiran gelap lebih sering gagal.',
                    style: AppText.caption,
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: busy || !_consented ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: Text(
                      busy
                          ? (state).step
                          : status?.enrolled == true
                              ? 'Daftarkan Ulang'
                              : 'Ambil Foto Wajah',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),

                  if (!_consented) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Centang persetujuan di atas untuk melanjutkan.',
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

class _StatusCard extends StatelessWidget {
  final dynamic status;

  const _StatusCard({required this.status});

  static final _format = DateFormat('d MMM yyyy', 'id_ID');

  @override
  Widget build(BuildContext context) {
    final enrolled = status.enrolled == true;
    final needsReenroll = status.needsReenroll(kFaceModelVersion) == true;

    if (needsReenroll) {
      // Ini keadaan yang paling perlu dijelaskan. Wajahnya sudah terdaftar,
      // tapi dengan model versi lama — jadi pencocokannya akan selalu
      // ditandai sampai didaftarkan ulang. Tanpa penjelasan ini, orangnya
      // tidak akan pernah tahu kenapa absensinya selalu bermasalah.
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.warningSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.autorenew, size: 18, color: AppColor.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perlu didaftarkan ulang',
                    style: AppText.bodyStrong
                        .copyWith(color: AppColor.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aplikasi sudah diperbarui, dan data wajah lama tidak '
                    'bisa dipakai lagi. Daftarkan ulang supaya absensi Anda '
                    'tidak selalu ditandai.',
                    style: AppText.caption.copyWith(color: AppColor.warning),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enrolled ? AppColor.successSurface : AppColor.background,
        borderRadius: BorderRadius.circular(14),
        border: enrolled ? null : Border.all(color: AppColor.border),
      ),
      child: Row(
        children: [
          Icon(
            enrolled ? Icons.verified_user_outlined : Icons.face_outlined,
            size: 18,
            color: enrolled ? AppColor.success : AppColor.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enrolled ? 'Wajah sudah terdaftar' : 'Wajah belum terdaftar',
                  style: AppText.bodyStrong.copyWith(
                    color: enrolled ? AppColor.success : AppColor.textPrimary,
                  ),
                ),
                if (enrolled && status.enrolledAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Didaftarkan ${_format.format(DateTime.parse(status.enrolledAt))}',
                    style: AppText.caption.copyWith(color: AppColor.success),
                  ),
                ],
                if (!enrolled && status.isRequired == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Perusahaan Anda mewajibkan verifikasi wajah. Absensi '
                    'belum bisa dilakukan sebelum wajah didaftarkan.',
                    style: AppText.caption,
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

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColor.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}