import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hris_mobile/constant/route/app_route.dart';
import 'package:hris_mobile/constant/theme/app_color.dart';
import 'package:hris_mobile/constant/theme/app_text.dart';

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
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      body: BlocConsumer<LoginCubit, LoginState>(
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

          return Column(
            children: [
              // Bidang biru di atas memberi aplikasi wajah sejak layar
              // pertama. Login yang seluruhnya putih terlihat seperti formulir
              // web yang dibungkus aplikasi.
              //
              // Logo sendirian jadi penanda brand — kotak ikon fingerprint
              // yang dulu ada di sini dilepas karena cuma bersaing dengan
              // logo untuk perhatian yang sama, bukan menambah arti.
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColor.primary, AppColor.primaryDark],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 56),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      SvgPicture.asset(
                        'assets/images/workonix-logo-dark.svg',
                        height: 36,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Masuk',
                        style: AppText.display.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gunakan email kantor Anda',
                        style: AppText.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              // Kartu form menimpa bagian bawah header, pola yang sama
              // dengan kartu shift di layar absensi. Dua blok rata yang cuma
              // ditumpuk terlihat seperti dua layar berbeda; kartu yang
              // menimpa membuatnya terbaca sebagai satu layar dengan lapisan.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColor.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primaryDark.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Email kantor',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            enabled: !isLoading,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),

                          if (state is LoginError) ...[
                            const SizedBox(height: 16),
                            _ErrorBox(message: state.message, code: ""),
                          ],

                          const SizedBox(height: 24),

                          FilledButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),

                          const SizedBox(height: 28),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColor.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: AppColor.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Belum punya password? Cek email undangan dari '
                                    'HR, lalu buat password Anda lewat tautan di '
                                    'dalamnya.',
                                    style: AppText.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit() {
    context.read<LoginCubit>().login(
      _emailController.text,
      _passwordController.text,
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColor.danger),
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
