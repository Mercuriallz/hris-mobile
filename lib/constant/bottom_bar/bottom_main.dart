import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/auth/profile/profile_page.dart';

import '../../features/approval/cubit/approval_cubit.dart';
import '../../features/approval/cubit/approval_state.dart';
import '../../features/approval/presentation/approval_inbox_page.dart';
import '../../features/attendance/presentation/attendance_page.dart';
import '../../features/leave/presentation/leave_page.dart';
import '../theme/app_color.dart';
import '../theme/app_text.dart';

/// Bottom bar dengan tab Persetujuan yang muncul sesuai keadaan.
///
/// Siapa penyetuju ditentukan garis pelaporan, bukan peran — jadi tidak ada
/// bendera di token yang bisa dipakai memutuskan. Yang dipakai justru
/// kenyataannya: kalau kotak masuknya berisi, tabnya muncul.
///
/// Konsekuensinya, penyetuju yang kotak masuknya kosong tidak melihat tabnya.
/// Itu diterima karena memang tidak ada yang perlu dilihat — dan jalan
/// masuknya tetap ada lewat menu di Profil.
class BottomMain extends StatefulWidget {
  const BottomMain({super.key});

  @override
  State<BottomMain> createState() => _BottomMainState();
}

class _BottomMainState extends State<BottomMain> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Diperiksa sekali saat aplikasi dibuka, tanpa menunggu orang membuka
    // tabnya. Penyetuju yang tidak tahu ada yang menunggu tidak akan
    // memeriksanya — dan itu justru masalah yang mau diselesaikan.
    context.read<ApprovalCubit>().fetchInbox(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalCubit, ApprovalState>(
      builder: (context, state) {
        final pending = context.read<ApprovalCubit>().pendingCount;
        final showApproval = pending > 0;

        // Riwayat keluar dari bottom bar, pindah jadi ikon di kepala layar
        // Absensi.
        //
        // Dengan Cuti masuk, lima tab tidak lagi terbaca di layar 380 piksel —
        // dan "Persetujuan" saja sudah tidak cukup lebarnya. Yang dikeluarkan
        // Riwayat karena dia tindakan melihat ke belakang yang dilakukan
        // sesekali, sementara Absensi dan Cuti adalah tindakan yang dilakukan.
        final screens = <Widget>[
          const AttendancePage(),
          const LeavePage(),
          if (showApproval) const ApprovalInboxPage(),
          const ProfilePage(),
        ];

        // Indeks dijaga tetap sah kalau tab Persetujuan hilang setelah
        // pengajuan terakhir diputuskan — tanpa ini, IndexedStack menunjuk ke
        // luar rentang dan aplikasinya jatuh justru setelah pekerjaan selesai.
        final safeIndex =
            _selectedIndex >= screens.length ? screens.length - 1 : _selectedIndex;

        return Scaffold(
          backgroundColor: AppColor.background,
          body: SafeArea(child: IndexedStack(index: safeIndex, children: screens)),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColor.surface,
              border: Border(top: BorderSide(color: AppColor.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    _NavItem(
                      index: 0,
                      icon: Icons.fingerprint,
                      label: 'Absensi',
                      selected: safeIndex == 0,
                      onTap: _select,
                    ),
                    _NavItem(
                      index: 1,
                      icon: Icons.beach_access_outlined,
                      label: 'Cuti',
                      selected: safeIndex == 1,
                      onTap: _select,
                    ),
                    if (showApproval)
                      _NavItem(
                        index: 2,
                        icon: Icons.inbox_outlined,
                        label: 'Persetujuan',
                        selected: safeIndex == 2,
                        badge: pending,
                        onTap: _select,
                      ),
                    _NavItem(
                      index: showApproval ? 3 : 2,
                      icon: Icons.person_outline_rounded,
                      label: 'Profil',
                      selected: safeIndex == (showApproval ? 3 : 2),
                      onTap: _select,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool selected;
  final int? badge;
  final void Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColor.primary : AppColor.textDisabled;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColor.primarySurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),

                  // Angka, bukan titik. "Ada yang menunggu" tidak cukup —
                  // penyetuju perlu tahu apakah ini satu pengajuan atau dua
                  // belas sebelum memutuskan mau membukanya sekarang atau
                  // nanti.
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: 4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: AppColor.danger,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColor.surface, width: 1.5),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          textAlign: TextAlign.center,
                          style: AppText.label.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppText.label.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}