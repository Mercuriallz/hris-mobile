import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constant/route/app_route.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../cubit/salary_slip_cubit.dart';
import '../cubit/salary_slip_state.dart';
import '../model/salary_slip_model.dart';
import 'salary_slip_pin_gate.dart';
import 'salary_slip_widgets.dart';

/// Daftar slip gaji milik sendiri, terbaru di atas.
///
/// Nominal disembunyikan dulu: halaman ini sering dibuka di tempat umum, dan
/// orang di sebelah tidak perlu ikut tahu gajinya.
class SalarySlipPage extends StatefulWidget {
  const SalarySlipPage({super.key});

  @override
  State<SalarySlipPage> createState() => _SalarySlipPageState();
}

class _SalarySlipPageState extends State<SalarySlipPage> {
  bool _showAmount = false;

  @override
  void initState() {
    super.initState();
    context.read<SalarySlipCubit>().fetch();
  }

  void _open(SalarySlip slip) => router.push('/salary-slips/${slip.id}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slip Gaji'),
        actions: [
          IconButton(
            tooltip: _showAmount ? 'Sembunyikan nominal' : 'Tampilkan nominal',
            icon: Icon(_showAmount ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _showAmount = !_showAmount),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (v) async {
              if (v != 'pin') return;
              final changed = await showDialog<bool>(context: context, builder: (_) => const SlipPinChangeDialog());
              if (changed == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN diganti')));
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'pin', child: Text('Ganti PIN'))],
          ),
        ],
      ),
      body: BlocBuilder<SalarySlipCubit, SalarySlipState>(
        builder: (context, state) {
          if (state is SalarySlipLoading || state is SalarySlipInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SalarySlipError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<SalarySlipCubit>().fetch(),
            );
          }

          final slips = (state as SalarySlipLoaded).slips;

          return RefreshIndicator(
            onRefresh: () => context.read<SalarySlipCubit>().fetch(silent: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (slips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum ada slip gaji',
                      message: 'Slip gaji akan muncul di sini setelah penggajian bulan ini selesai diproses HR.',
                    ),
                  )
                else ...[
                  Text('RIWAYAT SLIP', style: AppText.label),
                  const SizedBox(height: 10),
                  ...slips.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SalarySlipCard(
                          slip: s,
                          showAmount: _showAmount,
                          onTap: () => _open(s),
                        ),
                      )),
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
