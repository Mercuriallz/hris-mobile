import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../model/shift_swap_model.dart';
import '../repository/shift_swap_repository.dart';
import 'shift_swap_state.dart';

class ShiftSwapCubit extends Cubit<ShiftSwapState> {
  ShiftSwapCubit() : super(ShiftSwapInitial());

  /// Daftar kandidat disimpan supaya tidak hilang saat pratinjau dihitung.
  ///
  /// Tanpa ini, memilih rekan membuat daftarnya menghilang — dan orang yang
  /// ingin membandingkan dua pilihan harus memuat ulang seluruh layar.
  List<SwapCandidate> _candidates = [];

  String? _requesterShiftId;

  void loadCandidates(String employeeShiftId, {String? targetDate}) async {
    _requesterShiftId = employeeShiftId;
    emit(ShiftSwapLoadingCandidates());

    final result = await ShiftSwapRepository()
        .candidates(employeeShiftId, targetDate: targetDate);

    result.fold(
      (l) => emit(ShiftSwapError(l)),
      (r) {
        _candidates = r.data ?? <SwapCandidate>[];

        if (_candidates.isEmpty) {
          emit(ShiftSwapNoCandidates());
          return;
        }

        emit(ShiftSwapCandidatesLoaded(_candidates));
      },
    );
  }

  /// Menghitung akibat tukar tanpa menyimpan apa pun.
  ///
  /// Dipanggil begitu rekan dipilih. Peringatan yang muncul setelah atasan
  /// menolak berarti tiga orang sudah terlibat untuk sesuatu yang pengaju
  /// sendiri akan urungkan kalau tahu lebih awal.
  void preview(SwapCandidate candidate) async {
    final requesterShiftId = _requesterShiftId;
    if (requesterShiftId == null) return;

    emit(ShiftSwapPreviewing(candidate.employeeShiftId ?? ''));

    try {
      final dio = await DioService.getInstance();

      final response = await dio.post(
        "/me/shift-swap/preview",
        data: {
          "requesterShiftId": requesterShiftId,
          "counterpartShiftId": candidate.employeeShiftId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = SwapPreviewResponseModel.fromJson(response.data).data;

        if (data == null) {
          emit(ShiftSwapError('Pratinjau tidak lengkap. Coba lagi.'));
          return;
        }

        emit(ShiftSwapPreviewed(
          candidates: _candidates,
          selected: candidate,
          preview: data,
        ));
        return;
      }

      emit(ShiftSwapError(errorMessageFromResponse(response)));
    } catch (e) {
      emit(ShiftSwapError(errorMessage(e)));
    }
  }

  /// Kembali ke daftar tanpa memuat ulang dari server.
  void clearSelection() {
    if (_candidates.isEmpty) {
      emit(ShiftSwapNoCandidates());
      return;
    }
    emit(ShiftSwapCandidatesLoaded(_candidates));
  }

  void submit({
    required SwapCandidate candidate,
    required String reason,
  }) async {
    final requesterShiftId = _requesterShiftId;
    if (requesterShiftId == null) return;

    emit(ShiftSwapSubmitting());

    try {
      final dio = await DioService.getInstance();

      final response = await dio.post(
        "/me/shift-swap",
        data: {
          "requesterShiftId": requesterShiftId,
          "counterpartShiftId": candidate.employeeShiftId,
          if (reason.trim().isNotEmpty) "reason": reason.trim(),
        },
      );

      debugPrint("ajukan tukar shift: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(ShiftSwapSubmitted(
          'Pengajuan terkirim ke ${candidate.employeeName ?? 'rekan Anda'}',
        ));
        return;
      }

      emit(ShiftSwapError(errorMessageFromResponse(response)));
    } catch (e) {
      emit(ShiftSwapError(errorMessage(e)));
    }
  }
}