import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/timesheet_model.dart';
import '../repository/timesheet_repository.dart';

enum TimesheetListStatus { loading, loaded, error }

class TimesheetListState extends Equatable {
  final TimesheetListStatus status;
  final List<TimesheetActivity> rows;
  final int page;
  final int totalPages;
  final int total;
  final bool loadingMore;
  final String search;
  final String? visibility;
  final String? message;

  const TimesheetListState({
    this.status = TimesheetListStatus.loading,
    this.rows = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.loadingMore = false,
    this.search = '',
    this.visibility,
    this.message,
  });

  bool get hasMore => page < totalPages;
  bool get filtered => search.trim().isNotEmpty || visibility != null;

  TimesheetListState copyWith({
    TimesheetListStatus? status,
    List<TimesheetActivity>? rows,
    int? page,
    int? totalPages,
    int? total,
    bool? loadingMore,
    String? search,
    String? message,
  }) =>
      TimesheetListState(
        status: status ?? this.status,
        rows: rows ?? this.rows,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        loadingMore: loadingMore ?? this.loadingMore,
        search: search ?? this.search,
        visibility: visibility,
        message: message,
      );

  @override
  List<Object?> get props =>
      [status, rows.map((r) => '${r.id}:${r.title}:${r.visibility}').join(','), page, totalPages, total, loadingMore, search, visibility, message];
}

/// Satu cubit per tab (mine, team, shared), dibuat lokal oleh halamannya.
class TimesheetListCubit extends Cubit<TimesheetListState> {
  final String scope;
  final TimesheetRepository _repo;

  TimesheetListCubit(this.scope, {TimesheetRepository? repository})
      : _repo = repository ?? TimesheetRepository(),
        super(const TimesheetListState());

  /// Pencarian lama yang jawabannya datang terlambat tidak boleh menimpa
  /// hasil pencarian yang lebih baru.
  int _generation = 0;

  Future<void> load({bool silent = false}) async {
    final gen = ++_generation;
    final search = state.search;
    final visibility = state.visibility;
    if (!silent) {
      emit(TimesheetListState(search: search, visibility: visibility));
    }
    final res = await _repo.list(scope, search: search, visibility: visibility);
    if (gen != _generation || isClosed) return;
    res.fold(
      (l) => emit(TimesheetListState(
        status: TimesheetListStatus.error,
        message: l,
        search: search,
        visibility: visibility,
      )),
      (r) => emit(TimesheetListState(
        status: TimesheetListStatus.loaded,
        rows: r.rows,
        page: r.page,
        totalPages: r.totalPages,
        total: r.total,
        search: search,
        visibility: visibility,
      )),
    );
  }

  void setSearch(String value) {
    if (value == state.search) return;
    emit(TimesheetListState(search: value, visibility: state.visibility));
    load();
  }

  void setVisibility(String? value) {
    if (value == state.visibility) return;
    emit(TimesheetListState(search: state.search, visibility: value));
    load();
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    final gen = _generation;
    emit(state.copyWith(loadingMore: true));
    final res = await _repo.list(
      scope,
      page: state.page + 1,
      search: state.search,
      visibility: state.visibility,
    );
    if (gen != _generation || isClosed) return;
    res.fold(
      (l) => emit(state.copyWith(loadingMore: false, message: l)),
      (r) => emit(state.copyWith(
        status: TimesheetListStatus.loaded,
        rows: [...state.rows, ...r.rows],
        page: r.page,
        totalPages: r.totalPages,
        total: r.total,
        loadingMore: false,
      )),
    );
  }

  Future<String?> remove(String id) async {
    final res = await _repo.remove(id);
    return res.fold((l) => l, (_) {
      load(silent: true);
      return null;
    });
  }
}
