import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/leave_model.dart';
import '../repository/leave_repository.dart';
import 'leave_state.dart';

class LeaveCubit extends Cubit<LeaveState> {
  LeaveCubit() : super(LeaveInitial());


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