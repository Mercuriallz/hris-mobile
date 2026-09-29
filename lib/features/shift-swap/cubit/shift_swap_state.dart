import 'package:equatable/equatable.dart';

import '../model/shift_swap_model.dart';

abstract class ShiftSwapState extends Equatable {
  @override
  List<Object> get props => [];
}

class ShiftSwapInitial extends ShiftSwapState {}

class ShiftSwapLoadingCandidates extends ShiftSwapState {}

class ShiftSwapCandidatesLoaded extends ShiftSwapState {
  final List<SwapCandidate> candidates;

  ShiftSwapCandidatesLoaded(this.candidates);

  @override
  List<Object> get props =>
      [candidates.map((c) => c.employeeShiftId).join(',')];
}

/// Tidak ada rekan yang bisa diajak.
///
/// Dipisah dari daftar kosong biasa karena penjelasannya panjang dan
/// spesifik — dan layar kosong tanpa penjelasan terlihat seperti kerusakan.
class ShiftSwapNoCandidates extends ShiftSwapState {}

class ShiftSwapPreviewing extends ShiftSwapState {
  /// Kandidat yang sedang dihitung, supaya kartunya bisa ditandai.
  final String candidateShiftId;

  ShiftSwapPreviewing(this.candidateShiftId);

  @override
  List<Object> get props => [candidateShiftId];
}

class ShiftSwapPreviewed extends ShiftSwapState {
  final List<SwapCandidate> candidates;
  final SwapCandidate selected;
  final SwapPreviewData preview;

  ShiftSwapPreviewed({
    required this.candidates,
    required this.selected,
    required this.preview,
  });

  @override
  List<Object> get props => [
        selected.employeeShiftId ?? '',
        (preview.blockers ?? []).length,
        (preview.warnings ?? []).length,
      ];
}

class ShiftSwapSubmitting extends ShiftSwapState {}

class ShiftSwapSubmitted extends ShiftSwapState {
  final String message;

  ShiftSwapSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

class ShiftSwapError extends ShiftSwapState {
  final String message;

  ShiftSwapError(this.message);

  @override
  List<Object> get props => [message];
}