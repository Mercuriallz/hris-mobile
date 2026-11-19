import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../cubit/warning_letter_cubit.dart';
import '../model/warning_letter_model.dart';
import '../repository/warning_letter_repository.dart';
import 'warning_letter_widgets.dart';

/// Detail satu surat. Dibuka dari daftar atau dari ketukan notifikasi.
///
/// Membuka halaman ini mencatat di server bahwa surat sudah dibaca, dan HR
/// melihatnya di dashboard. Karena itu detailnya selalu diambil dari server,
/// bukan dari daftar yang sudah dimuat.
class WarningLetterDetailPage extends StatefulWidget {
  final String letterId;

  const WarningLetterDetailPage({super.key, required this.letterId});

  @override
  State<WarningLetterDetailPage> createState() => _WarningLetterDetailPageState();
}

class _WarningLetterDetailPageState extends State<WarningLetterDetailPage> {
  final _repo = WarningLetterRepository();
  WarningLetter? _letter;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await _repo.getOne(widget.letterId);
    if (!mounted) return;
    result.fold(
      (l) => setState(() => _error = l),
      (r) {
        setState(() => _letter = r);
        context.read<WarningLetterCubit>().markViewed(r.id);
      },
    );
  }

  Future<void> _openPdf() async {
    final letter = _letter;
    if (letter == null) return;
    setState(() => _downloading = true);
    final result = await _repo.downloadPdf(letter);
    if (!mounted) return;
    setState(() => _downloading = false);

    await result.fold(
      (l) async => _snack(l),
      (path) async {
        final opened = await OpenFilex.open(path, type: 'application/pdf');
        if (opened.type != ResultType.done && mounted) {
          _snack('Tidak ada aplikasi untuk membuka PDF. Pasang pembaca PDF lalu coba lagi.');
        }
      },
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final letter = _letter;

    return Scaffold(
      appBar: AppBar(title: Text(letter?.levelLabel ?? 'Surat dari HR')),
      body: _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : letter == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Header(letter: letter),
                    const SizedBox(height: 16),
                    ..._notices(letter),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PELANGGARAN', style: AppText.label),
                            const SizedBox(height: 6),
                            Text(letter.violation, style: AppText.h2),
                            const SizedBox(height: 14),
                            Text('DETAIL', style: AppText.label),
                            const SizedBox(height: 6),
                            Text(letter.detail, style: AppText.body),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _Row(label: 'Nomor surat', value: letter.letterNumber),
                            _Row(label: 'Tanggal terbit', value: formatLetterDate(letter.issuedDate)),
                            _Row(
                              label: letter.level == 'sp3' ? 'Akhir masa evaluasi' : 'Berlaku sampai',
                              value: formatLetterDate(letter.expiresDate),
                            ),
                            if (letter.companyName.isNotEmpty) _Row(label: 'Perusahaan', value: letter.companyName),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nextStepText(letter),
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _downloading ? null : _openPdf,
                      icon: _downloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      label: Text(_downloading ? 'Mengunduh...' : 'Lihat Surat (PDF)'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  List<Widget> _notices(WarningLetter letter) {
    Widget box(Color fg, Color bg, IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.bodyStrong.copyWith(color: fg)),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(body, style: AppText.body.copyWith(color: fg)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    switch (letter.status) {
      case 'revoked':
        return [
          box(AppColor.info, AppColor.infoSurface, Icons.undo, 'Surat ini sudah dicabut HR',
              letter.revokedReason ?? ''),
        ];
      case 'improved':
        return [
          box(AppColor.success, AppColor.successSurface, Icons.check_circle_outline,
              'Evaluasi selesai: ada perbaikan', letter.evaluationNote ?? ''),
        ];
      case 'terminated':
        return [
          box(AppColor.danger, AppColor.dangerSurface, Icons.info_outline,
              'Evaluasi selesai: hubungan kerja diakhiri', letter.evaluationNote ?? ''),
        ];
      case 'evaluation_due':
        return [
          box(AppColor.warning, AppColor.warningSurface, Icons.hourglass_bottom,
              'Masa evaluasi sudah selesai', 'HR sedang memutuskan hasil evaluasinya.'),
        ];
      default:
        return const [];
    }
  }

  String _nextStepText(WarningLetter letter) {
    if (!letter.isActive) return 'Surat ini sudah tidak berlaku, tapi tetap tersimpan sebagai riwayat.';
    switch (letter.level) {
      case 'verbal':
        return 'Kalau terjadi pelanggaran lagi sebelum teguran ini berakhir, HR akan memberikan SP 1.';
      case 'sp1':
        return 'Kalau terjadi pelanggaran lagi sebelum SP 1 berakhir, HR akan memberikan SP 2.';
      case 'sp2':
        return 'Kalau terjadi pelanggaran lagi sebelum SP 2 berakhir, HR akan memberikan SP 3.';
      default:
        return 'Selama masa evaluasi, HR menilai ada tidaknya perbaikan. Kalau tidak ada perbaikan, perusahaan dapat mengakhiri hubungan kerja.';
    }
  }
}

class _Header extends StatelessWidget {
  final WarningLetter letter;

  const _Header({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: WarningLevelBadge(level: letter.level, large: true)),
        const SizedBox(width: 8),
        const Spacer(),
        StatusBadge(label: letter.statusLabel, tone: warningStatusTone(letter.status)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppText.caption)),
          Expanded(child: Text(value, style: AppText.body)),
        ],
      ),
    );
  }
}
