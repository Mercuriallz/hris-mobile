import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../repository/approval_repository.dart';
import 'approval_state.dart';

class ApprovalCubit extends Cubit<ApprovalState> {
  ApprovalCubit() : super(ApprovalInitial());


  int pendingCount = 0;

  void fetchInbox({bool silent = false}) async {
    if (!silent) emit(ApprovalLoading());

    final result = await ApprovalRepository().getInbox();

    result.fold(
      (l) => emit(ApprovalError(l)),
      (r) {
        final items = r.data ?? [];
        pendingCount = items.length;
        emit(ApprovalLoaded(items));
      },
    );
  }

  void decide({
    required String approvalId,
    required bool approve,
    String? note,
  }) async {
    if (!approve && (note == null || note.trim().isEmpty)) {
      emit(ApprovalDecideError(
        'Alasan penolakan wajib diisi. Orang berhak tahu kenapa pengajuannya ditolak.',
      ));
      return;
    }

    emit(ApprovalDeciding(approvalId));

    try {
      final dio = await DioService.getInstance();

      final response = await dio.patch(
        "/me/approvals/$approvalId/decide",
        data: {
          "decision": approve ? "approve" : "reject",
          if (note != null && note.trim().isNotEmpty) "note": note.trim(),
        },
      );

      debugPrint("keputusan $approvalId: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(ApprovalDecided(
          approve ? 'Pengajuan disetujui' : 'Pengajuan ditolak',
        ));

        fetchInbox(silent: true);
        return;
      }

      emit(ApprovalDecideError(errorMessageFromResponse(response)));
      fetchInbox(silent: true);
    } catch (e) {
      emit(ApprovalDecideError(errorMessage(e)));
      fetchInbox(silent: true);
    }
  }
}