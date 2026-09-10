import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/auth/login/cubit/login_cubit.dart';
import 'package:hris_mobile/features/auth/profile/cubit/photo_cubit.dart';
import 'package:hris_mobile/features/auth/profile/cubit/photo_state.dart';
import 'package:hris_mobile/features/auth/profile/repository/profile_repository.dart';
import 'package:hris_mobile/features/face/presentation/face_enroll_page.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constant/route/app_route.dart';
import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../helper/device_helper.dart';
import '../../../helper/storage.dart';
import '../../approval/presentation/approval_inbox_page.dart';


/// Profil karyawan.
///
/// Nama, email, dan perangkat dibaca dari penyimpanan lokal — itu yang
/// membuat halaman ini tetap terbuka tanpa sinyal, dan tombol keluar harus
/// selalu bisa ditekan.
///
/// Fotonya menyusul dari server setelah layarnya tampil, bukan sebelum. Kalau
/// pemuatan foto dijadikan syarat, halaman ini ikut gagal saat sinyal buruk —
/// dan orang yang mau keluar dari aplikasi tersangkut karena avatarnya belum
/// termuat.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _name;
  String? _email;
  String? _deviceName;
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPhoto();
  }

  /// Foto diambil terpisah dan tidak menahan tampilnya layar.
  ///
  /// Gagal berarti avatarnya tetap inisial — bukan pesan kesalahan. Foto yang
  /// tidak termuat bukan sesuatu yang perlu ditindaklanjuti orangnya.
  Future<void> _loadPhoto() async {
    final result = await ProfileRepository().getMyProfile();

    if (!mounted) return;

    result.fold(
      (_) {},
      (response) => setState(() => _photoUrl = response.data?.photoUrl),
    );
  }

  /// Kamera saja, tidak dari galeri.
  ///
  /// Sama seperti swafoto absensi, dan alasannya sama juga: foto ini nantinya
  /// jadi acuan pencocokan wajah. Foto dari galeri bisa foto orang lain — dan
  /// memasang foto rekan sebagai acuan sendiri persis membatalkan gunanya
  /// pencocokan wajah.
  ///
  /// HR tetap bisa mengunggah dari berkas lewat dashboard, dan itu wajar:
  /// di sana ada orang yang memverifikasi.
  Future<void> _takePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (file == null || !mounted) return;
      context.read<PhotoCubit>().upload(file.path);
    } catch (e) {
      debugPrint('Gagal membuka kamera: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tidak bisa membuka kamera. Periksa izinnya di pengaturan HP.',
          ),
          backgroundColor: AppColor.danger,
        ),
      );
    }
  }

  Future<void> _load() async {
    final storage = SecureStorageService();

    final name = await storage.read("fullname");
    final email = await storage.read("email");
    final deviceName = await DeviceIdService().describe();

    if (!mounted) return;
    setState(() {
      _name = name;
      _email = email;
      _deviceName = deviceName;
      _loading = false;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text(
          'Anda perlu memasukkan email dan password lagi untuk masuk. '
          'Perangkat ini tetap terdaftar, jadi tidak perlu minta reset ke HR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColor.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<LoginCubit>().logout();
    if (mounted) router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = (_name?.isNotEmpty ?? false) ? _name! : '-';
    final email = (_email?.isNotEmpty ?? false) ? _email! : '-';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Kepala biru yang sama dengan layar Absensi dan Login. Tiga layar
          // dengan kepala yang sama membuat aplikasinya terasa satu, bukan
          // kumpulan halaman yang dijahit.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColor.primary, AppColor.primaryDark],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar sekaligus tombolnya. Ikon kamera kecil di sudut
                  // memberi tahu bahwa ini bisa diketuk — tanpa itu, tidak
                  // ada yang akan mencoba mengetuk fotonya sendiri.
                  BlocConsumer<PhotoCubit, PhotoState>(
                    listener: (context, state) {
                      if (state is PhotoUploaded) {
                        setState(() => _photoUrl = state.photoUrl);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Foto profil diperbarui'),
                            backgroundColor: AppColor.success,
                          ),
                        );
                      }

                      if (state is PhotoError) {
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
                      final uploading = state is PhotoUploading;

                      return Column(
                        children: [
                          InkWell(
                            onTap: uploading ? null : _takePhoto,
                            customBorder: const CircleBorder(),
                            child: Stack(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _photoUrl == null
                                      ? Center(
                                          child: Text(
                                            name.isNotEmpty && name != '-'
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: AppText.display
                                                .copyWith(color: Colors.white),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: _photoUrl!,
                                          fit: BoxFit.cover,
                                          // Inisial dipakai juga saat gagal.
                                          // URL bertanda tangan bisa
                                          // kedaluwarsa kalau halaman dibiarkan
                                          // terbuka lama, dan ikon rusak lebih
                                          // buruk daripada inisial.
                                          errorWidget: (_, _, _) => Center(
                                            child: Text(
                                              name.isNotEmpty && name != '-'
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: AppText.display.copyWith(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          placeholder: (_, _) => const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),

                                if (uploading)
                                  const Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0x66000000),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColor.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera_outlined,
                                        size: 14,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            uploading
                                ? state.step
                                : _photoUrl == null
                                    ? 'Ketuk untuk ambil foto profil'
                                    : 'Ketuk untuk ganti foto',
                            style: AppText.caption
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  Text(name, style: AppText.h1.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AppText.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _Section(
            title: 'PERANGKAT ABSENSI',
            children: [
              _Tile(
                icon: Icons.smartphone_outlined,
                title: _deviceName ?? '-',
                subtitle: 'Perangkat terdaftar',
              ),
              const Divider(height: 1, indent: 56),
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 12, 16, 14),
                child: Text(
                  'Absensi hanya bisa dilakukan dari perangkat ini. Jika Anda '
                  'ganti HP, minta HR mereset perangkat Anda terlebih dahulu.',
                  style: AppText.caption,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

        
          _Section(
            title: 'PERSETUJUAN',
            children: [
              _Tile(
                icon: Icons.inbox_outlined,
                title: 'Kotak masuk persetujuan',
                subtitle: 'Pengajuan yang menunggu persetujuan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ApprovalInboxPage(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height : 16),

        _Section(
          title: "Wajah",
          children: [
            _Tile(
            icon: Icons.face_outlined,
                title: 'Verifikasi Wajah',
                subtitle: 'Daftarkan wajah untuk keperluan absensi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FaceEnrollPage()),
                ),
          ),
          ]
        ),

          const SizedBox(height: 16),

          _Section(
            title: 'AKUN',
            children: [
              _Tile(
                icon: Icons.lock_outline,
                title: 'Ganti password',
                onTap: () => router.go('/change-password'),
              ),
              const Divider(height: 1, indent: 56),
              _Tile(
                icon: Icons.logout,
                title: 'Keluar',
                tone: AppColor.danger,
                onTap: _confirmLogout,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Cuti, lembur, dan persetujuan sementara masih lewat dashboard '
              'web.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(title, style: AppText.label),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? tone;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColor.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tone ?? AppColor.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body.copyWith(color: color)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppText.caption),
                ],
              ),
            ),
            if (onTap != null)
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