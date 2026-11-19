import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../model/salary_slip_model.dart';
import '../repository/salary_slip_repository.dart';
import 'salary_slip_widgets.dart';

/// Detail satu slip gaji. Selalu diambil dari server supaya rinciannya
/// lengkap dan sama dengan yang dipegang HR.
class SalarySlipDetailPage extends StatefulWidget {
  final String slipId;

  const SalarySlipDetailPage({super.key, required this.slipId});

  @override
  State<SalarySlipDetailPage> createState() => _SalarySlipDetailPageState();
}

class _SalarySlipDetailPageState extends State<SalarySlipDetailPage> {
  final _repo = SalarySlipRepository();
  SalarySlip? _slip;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await _repo.getOne(widget.slipId);
    if (!mounted) return;
    result.fold(
      (l) => setState(() => _error = l),
      (r) => setState(() => _slip = r),
    );
  }

  Future<void> _openPdf() async {
    final slip = _slip;
    if (slip == null) return;
    setState(() => _downloading = true);
    final result = await _repo.downloadPdf(slip);
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
    final slip = _slip;

    return Scaffold(
      appBar: AppBar(title: Text(slip == null ? 'Slip Gaji' : formatSlipMonth(slip.month))),
      body: _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : slip == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _NetPayHeader(slip: slip),
                    const SizedBox(height: 12),
                    if (slip.lwpDays > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColor.warningSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColor.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ada ${formatDays(slip.lwpDays)} hari cuti tidak dibayar di periode ini.',
                                style: AppText.body.copyWith(color: AppColor.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _LinesCard(
                      title: 'PENDAPATAN',
                      lines: slip.earnings,
                      totalLabel: 'Total pendapatan',
                      total: slip.grossPay,
                    ),
                    const SizedBox(height: 12),
                    _LinesCard(
                      title: 'POTONGAN',
                      lines: slip.deductions,
                      totalLabel: 'Total potongan',
                      total: slip.totalDeduction,
                      negative: true,
                    ),
                    const SizedBox(height: 12),
                    if (slip.employerContributions.any((l) => !l.isHelper)) ...[
                      _LinesCard(
                        title: 'DITANGGUNG PERUSAHAAN',
                        caption: 'Dibayar perusahaan di luar gaji, tidak memotong gaji bersih.',
                        lines: slip.employerContributions,
                        totalLabel: 'Total',
                        total: slip.totalEmployerContribution,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _Row(label: 'Periode', value: formatSlipPeriod(slip)),
                            _Row(
                              label: 'Hari dibayar',
                              value: '${formatDays(slip.paymentDays)} dari ${slip.totalWorkingDays} hari kerja',
                            ),
                            if (slip.positionTitle.isNotEmpty) _Row(label: 'Jabatan', value: slip.positionTitle),
                            if (slip.departmentName.isNotEmpty) _Row(label: 'Departemen', value: slip.departmentName),
                            _Row(
                              label: 'Rekening tujuan',
                              value: [
                                if (slip.bankName.isNotEmpty) slip.bankName,
                                maskAccountNumber(slip.bankAccountNumber),
                              ].join(' · '),
                            ),
                          ],
                        ),
                      ),
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
                      label: Text(_downloading ? 'Mengunduh...' : 'Lihat Slip (PDF)'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}

class _NetPayHeader extends StatelessWidget {
  final SalarySlip slip;

  const _NetPayHeader({required this.slip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColor.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GAJI BERSIH', style: AppText.label),
          const SizedBox(height: 4),
          Text(
            formatRupiah(slip.takeHomePay),
            style: AppText.display.copyWith(color: AppColor.primary),
          ),
          const SizedBox(height: 6),
          Text(formatSlipPeriod(slip), style: AppText.caption),
        ],
      ),
    );
  }
}

/// Rincian pendapatan / potongan. Komponen bantu (statistical atau tidak
/// masuk total) tetap ditampilkan tapi redup, supaya jelas itu bukan uang
/// yang dibayarkan.
class _LinesCard extends StatelessWidget {
  final String title;
  final String? caption;
  final List<SalarySlipLine> lines;
  final String totalLabel;
  final double total;
  final bool negative;

  const _LinesCard({
    required this.title,
    this.caption,
    required this.lines,
    required this.totalLabel,
    required this.total,
    this.negative = false,
  });

  @override
  Widget build(BuildContext context) {
    final paid = lines.where((l) => !l.isHelper).toList();
    final helpers = lines.where((l) => l.isHelper).toList();
    String amount(double v) => negative && v != 0 ? '- ${formatRupiah(v)}' : formatRupiah(v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.label),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: AppText.caption),
            ],
            const SizedBox(height: 8),
            if (paid.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Tidak ada', style: AppText.caption),
              ),
            ...paid.map((l) => _AmountRow(label: l.name, value: amount(l.amount))),
            ...helpers.map((l) => _AmountRow(
                  label: l.name,
                  value: formatRupiah(l.amount),
                  note: 'komponen bantu, tidak dibayarkan',
                  dimmed: true,
                )),
            const Divider(height: 20),
            _AmountRow(label: totalLabel, value: amount(total), strong: true),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final bool strong;
  final bool dimmed;

  const _AmountRow({
    required this.label,
    required this.value,
    this.note,
    this.strong = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = strong ? AppText.bodyStrong : AppText.body;
    final style = dimmed ? base.copyWith(color: AppColor.textDisabled) : base;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (note != null) Text(note!, style: AppText.caption.copyWith(color: AppColor.textDisabled)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
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
