import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../../attendance-history/model/attendance_history_model.dart';
import '../../attendance-history/repository/attendance_history_repository.dart';
import '../model/shift_swap_model.dart';
import '../repository/shift_swap_repository.dart';
import 'shift_swap_page.dart';

/// Pintu masuk Tukar Shift dari halaman Absensi.
///
/// Sebelumnya tukar shift hanya bisa dimulai dari Riwayat Absensi, dan orang
/// jarang mencari fitur ke depan di halaman yang namanya "riwayat". Di sini
/// jadwal yang belum berjalan langsung terlihat, dan pengajuan yang pernah
/// dikirim bisa dipantau statusnya di tempat yang sama.
class ShiftSwapHubPage extends StatefulWidget {
  const ShiftSwapHubPage({super.key});

  @override
  State<ShiftSwapHubPage> createState() => _ShiftSwapHubPageState();
}

class _ShiftSwapHubPageState extends State<ShiftSwapHubPage> {
  /// Seberapa jauh ke depan jadwal ditampilkan. Roster jarang disusun lebih
  /// jauh dari ini.
  static const _daysAhead = 45;

  static final _iso = DateFormat('yyyy-MM-dd');

  List<AttendanceHistoryData>? _shifts;
  List<SwapRequestData>? _requests;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final now = DateTime.now();
    // Dimulai bersamaan, ditunggu satu per satu.
    final historyCall = AttendanceHistoryRepository().getHistory(
      _iso.format(now),
      _iso.format(now.add(const Duration(days: _daysAhead))),
    );
    final requestsCall = ShiftSwapRepository().myRequests();
    final history = await historyCall;
    final myRequests = await requestsCall;
    if (!mounted) return;

    String? error;
    List<AttendanceHistoryData> shifts = [];
    List<SwapRequestData> requests = [];

    history.fold(
      (l) => error = l,
      (r) => shifts = (r.data ?? [])
          .where((s) => _isUpcoming(s) && s.employeeShiftId != null)
          .toList(),
    );
    myRequests.fold(
      (l) => error ??= l,
      (r) => requests = r.data ?? [],
    );

    setState(() {
      _error = error;
      _shifts = shifts;
      _requests = requests;
    });
  }

  /// Hanya shift yang belum mulai yang bisa ditukar.
  bool _isUpcoming(AttendanceHistoryData s) {
    if (s.scheduledStart == null) return false;
    try {
      return DateTime.parse(s.scheduledStart!).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> _openForm(AttendanceHistoryData s) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ShiftSwapFormPage(
          employeeShiftId: s.employeeShiftId!,
          myShiftName: s.shiftName ?? 'Shift',
          myWorkDate: s.workDate ?? '',
        ),
      ),
    );
    if (submitted == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final loading = _shifts == null && _error == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tukar Shift')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _shifts == null
              ? ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Pilih shift yang mau ditukar, lalu pilih rekan yang '
                        'bisa menggantikan. Tukar shift berlaku setelah '
                        'disetujui.',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 16),
                      Text('SHIFT MENDATANG', style: AppText.label),
                      const SizedBox(height: 10),
                      if (_shifts!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          child: EmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'Belum ada jadwal mendatang',
                            message: 'Jadwal shift yang belum berjalan akan '
                                'muncul di sini setelah roster disusun HR.',
                          ),
                        )
                      else
                        ..._shifts!.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ShiftCard(shift: s, onTap: () => _openForm(s)),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Text('PENGAJUAN SAYA', style: AppText.label),
                      const SizedBox(height: 10),
                      if ((_requests ?? []).isEmpty)
                        Text(
                          'Belum ada pengajuan tukar shift.',
                          style: AppText.caption,
                        )
                      else
                        ..._requests!.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RequestCard(request: r),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

String _date(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    return DateFormat('EEE, d MMM yyyy', 'id_ID').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String _clock(String? iso) {
  if (iso == null) return '--:--';
  try {
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return '--:--';
  }
}

class _ShiftCard extends StatelessWidget {
  final AttendanceHistoryData shift;
  final VoidCallback onTap;

  const _ShiftCard({required this.shift, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.swap_horiz, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_date(shift.workDate), style: AppText.bodyStrong),
                    const SizedBox(height: 2),
                    Text(
                      '${shift.shiftName ?? shift.shiftCode ?? 'Shift'} · '
                      '${_clock(shift.scheduledStart)}–${_clock(shift.scheduledEnd)}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColor.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final SwapRequestData request;

  const _RequestCard({required this.request});

  ({String label, StatusTone tone}) get _badge {
    switch (request.approvalStatus) {
      case 'approved':
        return (label: 'Disetujui', tone: StatusTone.success);
      case 'rejected':
        return (label: 'Ditolak', tone: StatusTone.danger);
      case 'cancelled':
        return (label: 'Dibatalkan', tone: StatusTone.neutral);
      default:
        return (label: 'Menunggu', tone: StatusTone.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final mine = request.isRequester != false;
    final other = mine ? request.counterpartName : request.requesterName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mine ? 'Tukar dengan ${other ?? '-'}' : 'Diajak tukar oleh ${other ?? '-'}',
                    style: AppText.bodyStrong,
                  ),
                ),
                StatusBadge(label: badge.label, tone: badge.tone),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(
              icon: Icons.event_outlined,
              text: '${_date(request.requesterWorkDate)} · ${request.requesterShiftName ?? '-'}',
            ),
            if (request.counterpartWorkDate != null) ...[
              const SizedBox(height: 4),
              InfoRow(
                icon: Icons.swap_horiz,
                text: '${_date(request.counterpartWorkDate)} · ${request.counterpartShiftName ?? '-'}',
              ),
            ],
            if (request.approvalStatus == 'rejected' &&
                (request.decisionNote?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                'Alasan: ${request.decisionNote}',
                style: AppText.caption.copyWith(color: AppColor.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
