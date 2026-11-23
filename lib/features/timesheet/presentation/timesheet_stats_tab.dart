import 'package:flutter/material.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../model/timesheet_model.dart';
import '../repository/timesheet_repository.dart';
import 'timesheet_widgets.dart';

/// Statistik jumlah aktivitas per bulan. Hanya angka, tidak membuka isi
/// catatan siapa pun.
class TimesheetStatsTab extends StatefulWidget {
  const TimesheetStatsTab({super.key});

  @override
  State<TimesheetStatsTab> createState() => _TimesheetStatsTabState();
}

class _TimesheetStatsTabState extends State<TimesheetStatsTab> with AutomaticKeepAliveClientMixin {
  TimesheetDashboardData? _data;
  String? _error;
  String _scope = 'mine'; // mine | department | summary

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final res = await TimesheetRepository().dashboard();
    if (!mounted) return;
    res.fold((l) => setState(() => _error = l), (r) => setState(() => _data = r));
  }

  TimesheetSeries _series(TimesheetDashboardData d) {
    switch (_scope) {
      case 'department':
        return d.department ?? d.mine;
      case 'summary':
        return d.summary;
      default:
        return d.mine;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    final d = _data;
    if (d == null) return const Center(child: CircularProgressIndicator());

    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final s = _series(d);
    final totalNow = s.current.fold<int>(0, (a, b) => a + b);
    final totalPrev = s.previous.fold<int>(0, (a, b) => a + b);
    final now = DateTime.now();
    final month = now.year == d.year ? now.month : 0;
    final thisMonth = month == 0 ? 0 : s.current[month - 1];

    final scopes = <(String, String)>[
      ('mine', 'Saya'),
      if (d.department != null) ('department', 'Departemen'),
      ('summary', 'Semua'),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottom),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final sc in scopes) ...[
                _ScopeChip(
                  label: sc.$2,
                  selected: _scope == sc.$1,
                  onTap: () => setState(() => _scope = sc.$1),
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'TAHUN ${d.year}',
                    value: '$totalNow',
                    unit: 'aktivitas',
                    note: 'Tahun ${d.year - 1}: $totalPrev',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'BULAN INI',
                    value: '$thisMonth',
                    unit: 'aktivitas',
                    note: month == 0 ? null : 'Bulan lalu: ${month > 1 ? s.current[month - 2] : 0}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aktivitas per bulan', style: AppText.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    _scope == 'mine'
                        ? 'Catatan milik Anda'
                        : _scope == 'department'
                            ? 'Semua anggota departemen Anda'
                            : 'Seluruh karyawan perusahaan',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 16),
                  MonthlyBars(series: s, year: d.year, currentMonth: month),
                ],
              ),
            ),
          ),
          if (_scope == 'department' && d.team.isNotEmpty) ...[
            const SizedBox(height: 14),
            _TeamCard(team: d.team, year: d.year),
          ],
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primarySurface : AppColor.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColor.primary : AppColor.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppText.bodyStrong.copyWith(
              fontSize: 13,
              color: selected ? AppColor.primary : AppColor.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? note;

  const _StatTile({required this.label, required this.value, required this.unit, this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.label),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppText.h1.copyWith(fontSize: 26)),
                const SizedBox(width: 6),
                Flexible(child: Text(unit, style: AppText.caption)),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final List<TimesheetMemberTotal> team;
  final int year;
  const _TeamCard({required this.team, required this.year});

  @override
  Widget build(BuildContext context) {
    final sorted = [...team]..sort((a, b) => b.current.compareTo(a.current));
    final maxVal = sorted.fold<int>(1, (m, e) => e.current > m ? e.current : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anggota tim', style: AppText.bodyStrong),
            const SizedBox(height: 2),
            Text('Jumlah aktivitas tahun $year', style: AppText.caption),
            const SizedBox(height: 14),
            for (final m in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColor.primarySurface,
                      child: Text(initialsOf(m.name), style: AppText.label.copyWith(color: AppColor.primary, fontSize: 10)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: m.current / maxVal,
                              minHeight: 6,
                              backgroundColor: AppColor.border,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text('${m.current}', textAlign: TextAlign.right, style: AppText.bodyStrong),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
