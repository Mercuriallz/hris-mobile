import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../helper/session_events.dart';
import '../repository/profile_repository.dart';
import 'my_profile_state.dart';

/// Data diri lengkap dari GET /me untuk halaman Data Diri.
///
/// Hanya di memori — tidak pernah ditulis ke penyimpanan lokal. NIK, NPWP,
/// dan nomor rekening yang tertinggal di disk bisa dibaca siapa pun yang
/// memegang HP-nya setelah orangnya keluar.
class MyProfileCubit extends Cubit<MyProfileState> {
  MyProfileCubit({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository(),
        super(MyProfileInitial()) {
    // Data pribadi: dikosongkan begitu sesi berakhir.
    _sessionSub = SessionEvents.cleared.listen((_) => reset());
  }

  final ProfileRepository _repository;
  late final StreamSubscription<void> _sessionSub;

  Future<void> fetch({bool silent = false}) async {
    if (!silent) emit(MyProfileLoading());
    final result = await _repository.getMyProfile();
    if (isClosed) return;
    result.fold(
      (l) => silent ? null : emit(MyProfileError(l)),
      (r) {
        final data = r.data;
        if (data == null) {
          if (!silent) emit(MyProfileError('Data profil tidak ditemukan.'));
          return;
        }
        emit(MyProfileLoaded(data));
      },
    );
  }

  void reset() {
    if (!isClosed) emit(MyProfileInitial());
  }

  @override
  Future<void> close() {
    _sessionSub.cancel();
    return super.close();
  }
}
