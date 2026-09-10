import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/route/app_route.dart';
import 'package:hris_mobile/constant/theme/app_color.dart';
import 'package:hris_mobile/constant/theme/app_text.dart';
import 'package:hris_mobile/features/auth/login/cubit/login_cubit.dart';
import 'package:hris_mobile/features/auth/login/cubit/login_state.dart';



/// Ganti password wajib.
///
/// Tidak bisa dilewati, dan tidak ada tombol kembali. Backend menolak seluruh
/// endpoint lain sampai ini selesai lewat PasswordChangeRequiredGuard, jadi
/// membiarkan orang keluar dari halaman ini cuma menghasilkan aplikasi yang
/// tidak bisa memuat apa pun.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: AppBar(
        title: const Text('Buat Password Baru'),
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.success,
              ),
            );
            router.go('/home');
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColor.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppColor.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Password Anda perlu diganti sebelum bisa memakai '
                          'aplikasi. Pilih password yang hanya Anda tahu — HR '
                          'tidak bisa melihatnya.',
                          style: AppText.caption.copyWith(
                            color: AppColor.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password saat ini',
                    prefixIcon: const Icon(Icons.key_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  enabled: !isLoading,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password baru',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    helperText: 'Minimal 8 karakter',
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _confirmController,
                  obscureText: _obscureNew,
                  enabled: !isLoading,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Ulangi password baru',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),

                // Ketidakcocokan ditampilkan sambil mengetik, bukan setelah
                // tombol ditekan. Menunggu sampai kirim berarti orang mengetik
                // dua kolom panjang lalu diberi tahu bahwa keduanya berbeda —
                // dan dia tidak bisa melihat mana yang salah.
                if (_confirmController.text.isNotEmpty &&
                    _newController.text != _confirmController.text) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 15,
                        color: AppColor.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Password tidak sama',
                        style: AppText.caption.copyWith(color: AppColor.danger),
                      ),
                    ],
                  ),
                ],

                if (state is LoginError) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColor.dangerSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColor.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.message,
                            style: AppText.body.copyWith(color: AppColor.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () => context.read<LoginCubit>().changePassword(
                            _currentController.text,
                            _newController.text,
                            _confirmController.text,
                          ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan Password'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}