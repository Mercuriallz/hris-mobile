import 'package:flutter/material.dart';
import 'package:hris_mobile/constant/theme/app_color.dart';
import 'package:hris_mobile/constant/theme/app_text.dart';

/// Empat nada status yang dipakai di seluruh aplikasi.
///
/// Dibatasi empat supaya artinya tetap terbaca. Begitu ada tujuh warna
/// status, orang berhenti membedakannya dan cuma membaca teksnya — dan kalau
/// begitu, warnanya tidak lagi berguna.
enum StatusTone { success, warning, danger, neutral, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  ({Color fg, Color bg}) get _colors {
    switch (tone) {
      case StatusTone.success:
        return (fg: AppColor.success, bg: AppColor.successSurface);
      case StatusTone.warning:
        return (fg: AppColor.warning, bg: AppColor.warningSurface);
      case StatusTone.danger:
        return (fg: AppColor.danger, bg: AppColor.dangerSurface);
      case StatusTone.info:
        return (fg: AppColor.info, bg: AppColor.infoSurface);
      case StatusTone.neutral:
        return (fg: AppColor.textSecondary, bg: AppColor.background);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c.fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.label.copyWith(color: c.fg, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

/// Layar kosong yang menjelaskan penyebabnya, bukan cuma mengatakan kosong.
///
/// "Tidak ada data" membuat orang mengira aplikasinya rusak. Menyebutkan
/// penyebab yang paling mungkin — biasanya rosternya belum disusun — dan siapa
/// yang harus dihubungi mengubahnya dari kebingungan jadi langkah berikutnya.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColor.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColor.primary),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: AppText.h2),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: AppText.caption),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Kegagalan memuat, dengan tombol coba lagi.
///
/// Dibedakan dari [EmptyState]: yang ini berarti sesuatu gagal dan bisa
/// diulang, yang itu berarti memang tidak ada isinya. Menyatukan keduanya
/// membuat orang menekan "coba lagi" untuk hari yang memang tidak ada
/// jadwalnya.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColor.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 30,
                color: AppColor.danger,
              ),
            ),
            const SizedBox(height: 18),
            Text('Gagal memuat', style: AppText.h2),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: AppText.caption),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris label–nilai yang dipakai di kartu absensi dan profil.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColor.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppText.caption)),
      ],
    );
  }
}

/// Cahaya warna yang sangat tipis berbentuk lingkaran, memudar ke tepi.
///
/// Dipakai di sudut layar berlatar putih supaya halaman punya kedalaman
/// tanpa perlu blok warna pekat yang bersaing dengan konten.
class SoftGlow extends StatelessWidget {
  final double size;
  final Color color;

  const SoftGlow({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
