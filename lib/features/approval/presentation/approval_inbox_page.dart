import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../cubit/approval_cubit.dart';
import '../cubit/approval_state.dart';
import '../model/approval_model.dart';
import 'approval_detail_page.dart';

/// Kotak masuk persetujuan, satu untuk semua jenis pengajuan.
///
/// Tidak ada penyaringan per jenis, dan itu disengaja. Penyetuju yang membuka
/// aplikasi ingin tahu "apa yang menunggu saya" — bukan "apa cuti yang
/// menunggu saya". Memisahkannya per jenis berarti dia harus memeriksa tiga
/// tempat dan mengingat mana yang sudah dilihat.
class ApprovalInboxPage extends StatefulWidget {
  const ApprovalInboxPage({super.key});

  @override
  State<ApprovalInboxPage> createState() => _ApprovalInboxPageState();
}

class _ApprovalInboxPageState extends State<ApprovalInboxPage> {
  @override
  void initState() {
    super.initState();
    context.read<ApprovalCubit>().fetchInbox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persetujuan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ApprovalCubit>().fetchInbox(),
          ),
        ],
      ),
      body: BlocConsumer<ApprovalCubit, ApprovalState>(
        listener: (context, state) {
          if (state is ApprovalDecided) {
            _snack(state.message, isError: false);
          }
          if (state is ApprovalDecideError) {
            _snack(state.message, isError: true);
          }
        },

        // State keputusan tidak membangun ulang daftar — kalau ikut, daftarnya
        // berkedip kosong setiap kali ada pesan.
        buildWhen: (previous, current) =>
            current is! ApprovalDecided && current is! ApprovalDecideError,

        builder: (context, state) {
          if (state is ApprovalLoading || state is ApprovalInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ApprovalError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<ApprovalCubit>().fetchInbox(),
            );
          }

          final decidingId =
              state is ApprovalDeciding ? state.approvalId : null;

          final items = state is ApprovalLoaded
              ? state.items
              : context.read<ApprovalCubit>().state is ApprovalLoaded
                  ? (context.read<ApprovalCubit>().state as ApprovalLoaded).items
                  : <ApprovalData>[];

          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.done_all,
              title: 'Tidak ada yang menunggu',
              message: 'Semua pengajuan yang jadi giliran Anda sudah '
                  'diputuskan. Tarik ke bawah untuk memeriksa lagi.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ApprovalCubit>().fetchInbox(silent: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ApprovalCard(
                item: items[index],
                isDeciding: decidingId == items[index].id,
              ),
            ),
          );
        },
      ),
    );
  }

  void _snack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColor.danger : AppColor.success,
          duration: Duration(seconds: isError ? 5 : 2),
        ),
      );
  }
}

class _ApprovalCard extends StatelessWidget {
  final ApprovalData item;
  final bool isDeciding;

  const _ApprovalCard({required this.item, required this.isDeciding});

  static final _dateFormat = DateFormat('d MMM, HH:mm', 'id_ID');

  ({StatusTone tone, IconData icon}) get _typeVisual {
    switch (item.requestType) {
      case ApprovalTypes.leave:
        return (tone: StatusTone.info, icon: Icons.beach_access_outlined);
      case ApprovalTypes.overtime:
        return (tone: StatusTone.warning, icon: Icons.more_time);
      default:
        return (tone: StatusTone.neutral, icon: Icons.edit_note);
    }
  }

  /// Langkah yang sedang giliran penyetuju ini.
  Steps? get _currentStep {
    final steps = item.steps;
    if (steps == null) return null;

    for (final step in steps) {
      if (step.stepOrder == item.currentStep) return step;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visual = _typeVisual;
    final step = _currentStep;
    final totalSteps = item.steps?.length ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(
                  label: ApprovalTypes.labels[item.requestType] ?? 'Pengajuan',
                  tone: visual.tone,
                  icon: visual.icon,
                ),
                const Spacer(),
                Text(
                  item.createdAt == null
                      ? ''
                      : _dateFormat
                          .format(DateTime.parse(item.createdAt!).toLocal()),
                  style: AppText.label,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              item.requester?.fullName ?? 'Karyawan',
              style: AppText.bodyStrong,
            ),
            if (item.requester?.employeeNumber != null)
              Text(item.requester!.employeeNumber!, style: AppText.label),

            const SizedBox(height: 8),

            // Ringkasan yang dibekukan modul asal. Kartunya tidak perlu tahu
            // apa pun tentang cuti maupun absensi — dan itu yang membuat
            // menambah jenis pengajuan baru tidak menyentuh layar ini.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(item.summary ?? '-', style: AppText.body),
            ),

            if (step != null && totalSteps > 1) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.account_tree_outlined,
                    size: 14,
                    color: AppColor.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Persetujuan ke-${item.currentStep} dari $totalSteps'
                      // Perannya disebut hanya kalau bukan atasan langsung.
                      // Atasan langsung itu bentuk bawaannya — menyebutnya
                      // di setiap kartu menambah teks tanpa menambah
                      // informasi. Yang perlu disebut justru yang tidak
                      // biasa: lapis HR, dan rekan tukar shift.
                      '${_stepRoleSuffix(step.approverRole)}',
                      style: AppText.label,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Satu tombol yang membuka detail, bukan dua tombol keputusan
            // langsung di kartu.
            //
            // Untuk koreksi absensi, swafoto adalah satu-satunya bukti — dan
            // tombol Setujui di daftar berarti orang bisa memutuskan tanpa
            // pernah melihatnya. Memindahkannya ke halaman detail menambah satu
            // ketukan, dan ketukan itu yang memastikan buktinya terlihat.
            FilledButton.icon(
              onPressed: isDeciding ? null : () => _openDetail(context),
              icon: isDeciding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: Text(isDeciding ? 'Memproses...' : 'Periksa & Putuskan'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    final decided = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ApprovalDetailPage(approvalId: item.id!),
      ),
    );

    // Kotak masuk dimuat ulang hanya kalau ada keputusan. Kembali tanpa
    // memutuskan tidak perlu memicu permintaan jaringan.
    if (decided == true && context.mounted) {
      context.read<ApprovalCubit>().fetchInbox(silent: true);
    }
  }
}

String _stepRoleSuffix(String? role) {
  switch (role) {
    case 'hr':
      return ' · lapis HR';
    case 'counterpart':
      return ' · rekan tukar shift';
    default:
      return '';
  }
}