import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hris_mobile/constant/route/app_route.dart';
import 'package:hris_mobile/constant/theme/app_color.dart';
import 'package:hris_mobile/constant/theme/app_text.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';

import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Sapaan mengikuti jam, karena orang membuka aplikasi ini tepat sebelum
  /// absen — sapaan yang cocok dengan waktunya terasa seperti aplikasi yang
  /// tahu konteks, bukan formulir generik.
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColor.surface,
        body: Stack(
          children: [
            BlocConsumer<LoginCubit, LoginState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  router.go('/home');
                }
                if (state is LoginMustChangePassword) {
                  router.go('/change-password');
                }
              },
              builder: (context, state) {
                final isLoading = state is LoginLoading;

                // Header dan form diletakkan dalam satu scroll biasa. Saat keyboard
                // muncul, seluruh layar bergeser naik bersama, jadi field yang
                // sedang diisi tidak tertutup.
                //
                // Sengaja tidak memakai SliverFillRemaining: ia mengukur tinggi
                // lewat intrinsic height, yang tidak cocok dengan AnimatedSize di
                // kotak error — hasilnya overflow saat error muncul. Sisa layar
                // di bawah form cukup diwarnai putih lewat background Scaffold.
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _Header(greeting: _greeting),
                      _buildSheet(context, state, isLoading),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, LoginState state, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: SafeArea(
        top: false,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Masuk ke akun Anda', style: AppText.h1),
              const SizedBox(height: 4),
              Text(
                'Gunakan email kantor yang terdaftar di HR.',
                style: AppText.caption,
              ),
              const SizedBox(height: 28),

              _FieldLabel('Email kantor'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: const InputDecoration(
                  hintText: 'nama@perusahaan.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              _FieldLabel('Password'),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enabled: !isLoading,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // Error muncul dengan animasi tinggi supaya tombol di bawahnya
              // bergeser halus, bukan melompat tepat saat jari mau menekan.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: state is LoginError
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _ErrorBox(message: state.message, code: null),
                      )
                    : const SizedBox(width: double.infinity),
              ),

              const SizedBox(height: 28),

              // Tombol baru aktif setelah kedua field terisi. Menolak submit
              // kosong di sisi klien lebih cepat dan lebih jelas daripada
              // menunggu backend membalas "email wajib diisi".
              FilledButton(
                onPressed: isLoading || !_canSubmit ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Masuk'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // Penjelasan undangan HR dipindah ke balik tautan. Mayoritas
              // pengguna sudah punya password; teks panjang yang selalu
              // tampil cuma jadi kebisingan bagi mereka.
              Center(
                child: TextButton(
                  onPressed: () => _showFirstLoginHelp(context),
                  child: const Text('Belum punya password?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFirstLoginHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColor.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Login pertama kali', style: AppText.h2),
              const SizedBox(height: 8),
              Text(
                'Cek email undangan dari HR, lalu buat password Anda lewat '
                'tautan di dalamnya. Setelah itu kembali ke sini dan masuk '
                'dengan email kantor Anda.',
                style: AppText.body.copyWith(color: AppColor.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak menemukan emailnya? Periksa folder spam, atau minta HR '
                'mengirim ulang undangan.',
                style: AppText.caption,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }
}

/// Bagian atas berwarna biru tua dengan logo dan sapaan.
///
/// Biru tua dipakai di sini saja; form di bawahnya tetap putih supaya isian
/// terbaca jelas. Kontras keduanya yang membuat halaman tidak terasa datar.
class _Header extends StatelessWidget {
  final String greeting;

  const _Header({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primaryDark, Color(0xFF0A2C66)],
        ),
      ),
      child: Stack(
        children: [
          // Cahaya biru muda di pojok, motif yang sama dengan splash, supaya
          // blok biru tua punya kedalaman dan tidak terlihat seperti cat rata.
          Positioned(
            top: -150,
            right: -130,
            child: SoftGlow(size: 380, color: AppColor.primaryLight),
          ),
          // Tutup putih bersudut melengkung di dasar header, menyambung ke
          // form di bawahnya, supaya form terbaca sebagai sheet yang naik
          // menimpa header.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 68),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/images/workonix-logo-dark.svg',
                    height: 36,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.waving_hand_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          greeting,
                          style: AppText.label.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Baris kedua memakai biru muda yang sama dengan titik di
                  // logo, jadi aksennya terasa bagian dari merek.
                  Text.rich(
                    TextSpan(
                      style: AppText.display.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.15,
                      ),
                      children: const [
                        TextSpan(text: 'Siap mulai\n'),
                        TextSpan(
                          text: 'bekerja hari ini?',
                          style: TextStyle(color: Color(0xFF7FB3F5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppText.bodyStrong),
    );
  }
}

/// Kotak error yang menambahkan petunjuk untuk penolakan yang butuh tindakan
/// khusus.
///
/// Pesan dari backend sudah bisa dibaca, tapi ada kasus yang jalan keluarnya
/// tidak jelas dari pesannya sendiri — dan itu berakhir di meja HR kalau tidak
/// dijelaskan di sini.
class _ErrorBox extends StatelessWidget {
  final String message;
  final String? code;

  const _ErrorBox({required this.message, required this.code});

  String? get _hint {
    switch (code) {
      case 'DeviceNotRecognized':
        return 'Akun Anda terikat ke HP lain. Kalau Anda memang ganti HP, '
            'minta HR mereset perangkat Anda dulu.';
      case 'TooManyAttempts':
        return 'Tunggu beberapa menit sebelum mencoba lagi.';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hint;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.dangerSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColor.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppText.body.copyWith(color: AppColor.danger),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    hint,
                    style: AppText.caption.copyWith(color: AppColor.danger),
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
