import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/approval_detail_repository.dart';
import 'approval_detail_state.dart';

class ApprovalDetailCubit extends Cubit<ApprovalDetailState> {
  ApprovalDetailCubit() : super(ApprovalDetailInitial());

  void fetchDetail(String approvalId) async {
    emit(ApprovalDetailLoading());

    final result = await ApprovalDetailRepository().getDetail(approvalId);

    result.fold(
      (l) => emit(ApprovalDetailError(l)),
      (r) {
        final approval = r.data?.approval;
        final detail = r.data?.detail;

        if (approval == null || detail == null) {
          emit(ApprovalDetailError('Detail pengajuan tidak lengkap.'));
          return;
        }

        emit(ApprovalDetailLoaded(approval, detail));
      },
    );
  }
}