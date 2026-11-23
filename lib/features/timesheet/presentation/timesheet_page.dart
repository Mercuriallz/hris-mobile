import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../constant/theme/app_widget.dart';
import '../cubit/timesheet_list_cubit.dart';
import '../model/timesheet_model.dart';
import '../repository/timesheet_repository.dart';
import 'timesheet_form_page.dart';
import 'timesheet_stats_tab.dart';
import 'timesheet_widgets.dart';

/// Daily Timesheet: Saya, Tim, Bersama, dan Statistik.
class TimesheetPage extends StatefulWidget {
  const TimesheetPage({super.key});

  @override
  State<TimesheetPage> createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Timesheet')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: PillTabs(controller: _tabs, labels: const ['Saya', 'Tim', 'Bersama', 'Statistik']),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _ListTab(scope: 'mine'),
                _ListTab(scope: 'team'),
                _ListTab(scope: 'shared'),
                TimesheetStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  final String scope;
  const _ListTab({required this.scope});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TimesheetListCubit(scope)..load(),
      child: _ListBody(scope: scope),
    );
  }
}

class _ListBody extends StatefulWidget {
  final String scope;
  const _ListBody({required this.scope});

  @override
  State<_ListBody> createState() => _ListBodyState();
}

class _ListBodyState extends State<_ListBody> with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  ({int minutes, int count})? _today;

  @override
  bool get wantKeepAlive => true;

  bool get _mine => widget.scope == 'mine';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        context.read<TimesheetListCubit>().loadMore();
      }
    });
    if (_mine) _loadToday();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Total hari ini dihitung dari permintaan sendiri (rentang hari ini saja),
  /// bukan dari halaman daftar yang bisa terpotong.
  Future<void> _loadToday() async {
    final n = DateTime.now();
    final today = '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    final res = await TimesheetRepository().list('mine', limit: 100, from: today, to: today);
    if (!mounted) return;
    res.fold((_) {}, (r) {
      setState(() => _today = (minutes: r.rows.fold<int>(0, (s, e) => s + e.durationMinutes), count: r.total));
    });
  }

  Future<void> _refresh() async {
    await context.read<TimesheetListCubit>().load(silent: true);
    if (_mine) await _loadToday();
  }

  Future<void> _open({TimesheetActivity? editing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TimesheetFormPage(editing: editing)),
    );
    if (saved == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _delete(TimesheetActivity a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surface,
        title: Text('Hapus aktivitas?', style: AppText.h2),
        content: Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColor.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await context.read<TimesheetListCubit>().remove(a.id);
    if (!mounted) return;
    if (err != null) {
      _snack(err, error: true);
    } else {
      _snack('Aktivitas dihapus');
      _loadToday();
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColor.danger : AppColor.success,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return BlocBuilder<TimesheetListCubit, TimesheetListState>(
      builder: (context, state) {
        final loaded = state.status == TimesheetListStatus.loaded;

        final content = RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 0, 16, (_mine ? 96 : 24) + bottom),
            children: [
              if (_mine) ...[
                TodayHero(
                  minutes: _today?.minutes ?? 0,
                  count: _today?.count ?? 0,
                  loading: _today == null,
                ),
                const SizedBox(height: 14),
              ],
              _FilterBar(
                controller: _search,
                showVisibility: _mine,
                visibility: state.visibility,
                onSearch: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), () {
                    if (mounted) context.read<TimesheetListCubit>().setSearch(v);
                  });
                },
                onVisibility: (v) => context.read<TimesheetListCubit>().setVisibility(v),
              ),
              const SizedBox(height: 12),
              ..._body(state, loaded),
            ],
          ),
        );

        if (!_mine) return content;
        return Stack(children: [
          content,
          Positioned(
            right: 16,
            bottom: 16 + bottom,
            // Bayangan buatan sendiri, bukan elevasi bawaan: warnanya mengikuti
            // palet dan tidak berubah jadi garis gelap di mode terang.
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                shadows: [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _open(),
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                shape: const StadiumBorder(),
                icon: const Icon(Icons.add),
                label: Text('Catat', style: AppText.bodyStrong.copyWith(color: Colors.white, letterSpacing: 0)),
              ),
            ),
          ),
        ]);
      },
    );
  }

  List<Widget> _body(TimesheetListState state, bool loaded) {
    if (state.status == TimesheetListStatus.loading) {
      return const [Padding(padding: EdgeInsets.only(top: 48), child: Center(child: CircularProgressIndicator()))];
    }
    if (state.status == TimesheetListStatus.error) {
      return [
        SizedBox(
          height: 320,
          child: ErrorState(
            message: state.message ?? 'Gagal memuat',
            onRetry: () => context.read<TimesheetListCubit>().load(),
          ),
        ),
      ];
    }
    if (state.rows.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: EmptyState(
            icon: state.filtered ? Icons.search_off : Icons.assignment_outlined,
            title: state.filtered ? 'Tidak ada yang cocok' : 'Belum ada aktivitas',
            message: state.filtered
                ? 'Coba kata kunci lain atau hapus filter.'
                : _mine
                    ? 'Catat pekerjaan harian Anda dengan tombol Catat di bawah.'
                    : widget.scope == 'team'
                        ? 'Aktivitas rekan satu departemen yang dibagikan akan muncul di sini.'
                        : 'Aktivitas yang dibagikan ke semua karyawan akan muncul di sini.',
          ),
        ),
      ];
    }

    final out = <Widget>[];
    String? lastDate;
    for (final a in state.rows) {
      if (a.workDate != lastDate) {
        out.add(DayHeader(isoDate: a.workDate));
        lastDate = a.workDate;
      }
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ActivityCard(
          activity: a,
          showOwner: !_mine,
          onEdit: _mine ? () => _open(editing: a) : null,
          onDelete: _mine ? () => _delete(a) : null,
        ),
      ));
    }
    if (state.loadingMore) {
      out.add(const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));
    } else if (state.hasMore) {
      out.add(Center(
        child: TextButton(
          onPressed: () => context.read<TimesheetListCubit>().loadMore(),
          child: const Text('Muat lebih banyak'),
        ),
      ));
    }
    return out;
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final bool showVisibility;
  final String? visibility;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onVisibility;

  const _FilterBar({
    required this.controller,
    required this.showVisibility,
    required this.visibility,
    required this.onSearch,
    required this.onVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari aktivitas…',
            prefixIcon: Icon(Icons.search, color: AppColor.textSecondary),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: AppColor.textSecondary, size: 18),
                    onPressed: () {
                      controller.clear();
                      onSearch('');
                    },
                  ),
          ),
        ),
        if (showVisibility) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Semua', selected: visibility == null, onTap: () => onVisibility(null)),
                for (final v in const ['private', 'team', 'all']) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: visibilityInfo(v).label,
                    icon: visibilityInfo(v).icon,
                    selected: visibility == v,
                    onTap: () => onVisibility(v),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColor.primarySurface : AppColor.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColor.primary : AppColor.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? AppColor.primary : AppColor.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13,
                  color: selected ? AppColor.primary : AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
