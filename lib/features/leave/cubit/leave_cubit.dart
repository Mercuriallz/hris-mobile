import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/leave_model.dart';
import '../repository/leave_repository.dart';
import 'leave_state.dart';

class LeaveCubit extends Cubit<LeaveState> {
  LeaveCubit() : super(LeaveInitial());

  /// Tiga permintaan sekaligus, bukan berurutan.
  ///
  /// Saldo, jenis cuti, dan riwayat tidak saling bergantung — menunggunya satu
  /// per satu berarti layar kosong tiga kali lebih lama di jaringan seluler.
  void fetchAll({bool silent = false}) async {
    if (!silent) emit(LeaveLoading());

    final repository = LeaveRepository();

    final balanceFuture = repository.getBalance();
    final typesFuture = repository.getTypes();
    final requestsFuture = repository.getMyRequests();

    final balanceResult = await balanceFuture;
    final typesResult = await typesFuture;
    final requestsResult = await requestsFuture;

    LeaveBalanceData? balance;
    String? balanceError;

    balanceResult.fold(
      (l) => balanceError = l,
      (r) => balance = r.data,
    );

    // Saldo yang gagal berarti seluruh layar tidak berguna — angka sisa jatah
    // adalah alasan utama orang membuka halaman ini.
    if (balanceError != null) {
      emit(LeaveError(balanceError!));
      return;
    }

    if (balance == null) {
      emit(LeaveError('Saldo cuti tidak lengkap. Coba lagi.'));
      return;
    }

    var types = <LeaveTypeData>[];
    typesResult.fold(
      (_) => types = [],
      (r) => types = r.data ?? [],
    );

    var requests = <LeaveRequestData>[];
    requestsResult.fold(
      (_) => requests = [],
      (r) => requests = r.data ?? [],
    );

    emit(LeaveLoaded(
      balance!,
      types.where((t) => t.isActive ?? true).toList(),
      requests,
    ));
  }
}