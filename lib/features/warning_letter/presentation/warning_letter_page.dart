import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../../../constant/route/app_route.dart';
import '../cubit/warning_letter_cubit.dart';
import '../cubit/warning_letter_state.dart';
import '../model/warning_letter_model.dart';
import 'warning_letter_widgets.dart';

/// Daftar teguran dan surat peringatan milik sendiri.
///
/// Yang masih berlaku ditaruh di atas dan dipisah dari riwayat. Orang yang
/// membuka halaman ini ingin tahu "saya sedang kena apa sekarang" — surat
/// yang sudah berakhir setahun lalu cuma konteks.
class WarningLetterPage extends StatefulWidget {
  const WarningLetterPage({super.key});

  @override
  State<WarningLetterPage> createState() => _WarningLetterPageState();
}

class _WarningLetterPageState extends State<WarningLetterPage> {
  @override
  void initState() {
    super.initState();
    context.read<WarningLetterCubit>().fetch();
  }

  Future<void> _open(WarningLetter letter) async {
    await router.push('/warning-letters/${letter.id}');
    if (mounted) context.read<WarningLetterCubit>().fetch(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surat dari HR')),
      body: BlocBuilder<WarningLetterCubit, WarningLetterState>(
        builder: (context, state) {
          if (state is WarningLetterLoading || state is WarningLetterInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WarningLetterError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<WarningLetterCubit>().fetch(),
            );
          }

          final letters = (state as WarningLetterLoaded).letters;
          final active = letters.where((l) => l.isActive).toList();
          final past = letters.where((l) => !l.isActive).toList();

          return RefreshIndicator(
            onRefresh: () => context.read<WarningLetterCubit>().fetch(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (letters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyState(
                      icon: Icons.verified_outlined,
                      title: 'Tidak ada surat',
                      message: 'Teguran dan surat peringatan dari HR akan muncul di sini.',
                    ),
                  )
                else ...[
                  _Summary(active: active),
                  const SizedBox(height: 20),
                  if (active.isNotEmpty) ...[
                    Text('MASIH BERLAKU', style: AppText.label),
                    const SizedBox(height: 10),
                    ...active.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: WarningLetterCard(letter: l, onTap: () => _open(l)),
                        )),
                    const SizedBox(height: 10),
                  ],
                  if (past.isNotEmpty) ...[
                    Text('RIWAYAT', style: AppText.label),
                    const SizedBox(height: 10),
                    ...past.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: WarningLetterCard(letter: l, onTap: () => _open(l)),
                        )),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Ringkasan di atas: tingkat tertinggi yang sedang berlaku.
class _Summary extends StatelessWidget {
  final List<WarningLetter> active;

  const _Summary({required this.active});

  static const _order = ['verbal', 'sp1', 'sp2', 'sp3'];

  @override
  Widget build(BuildContext context) {
    if (active.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.successSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColor.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada teguran atau SP yang sedang berlaku.',
                style: AppText.body.copyWith(color: AppColor.success),
              ),
            ),
          ],
        ),
      );
    }

    final top = [...active]..sort((a, b) => _order.indexOf(b.level) - _order.indexOf(a.level));
    final current = top.first;
    final color = warningLevelColor(current.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 8),
              Text('Sedang berlaku: ${current.levelLabel}', style: AppText.bodyStrong.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            current.level == 'sp3'
                ? 'Masa evaluasi sampai ${formatLetterDate(current.expiresDate)}. Hasilnya akan diputuskan HR setelah masa evaluasi selesai.'
                : 'Berlaku sampai ${formatLetterDate(current.expiresDate)}. Pelanggaran berikutnya dalam masa ini akan naik ke tingkat selanjutnya.',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
