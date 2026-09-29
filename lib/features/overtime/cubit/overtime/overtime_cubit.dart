import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_mobile/features/overtime/model/overtime_model.dart';
import 'package:hris_mobile/features/overtime/repository/overtime_repository.dart';


import 'overtime_state.dart';

class OvertimeCubit extends Cubit<OvertimeState> {
  OvertimeCubit() : super(OvertimeInitial());

  void fetchRequests({bool silent = false}) async {
    if (!silent) emit(OvertimeLoading());

    final result = await OvertimeRepository().getMyRequests();

    result.fold(
      (l) => emit(OvertimeError(l)),
      (r) => emit(OvertimeLoaded(r.data ?? <OvertimeRequestData>[])),
    );
  }
}