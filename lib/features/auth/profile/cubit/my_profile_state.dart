import 'package:equatable/equatable.dart';

import '../model/my_profile_model.dart';

abstract class MyProfileState extends Equatable {
  @override
  List<Object> get props => [];
}

class MyProfileInitial extends MyProfileState {}

class MyProfileLoading extends MyProfileState {}

/// Dibandingkan per objek: setiap muat ulang yang berhasil selalu dipancarkan,
/// supaya perubahan dari HR langsung terlihat setelah tarik-untuk-muat-ulang.
class MyProfileLoaded extends MyProfileState {
  final MyProfileData profile;

  MyProfileLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}

class MyProfileError extends MyProfileState {
  final String message;

  MyProfileError(this.message);

  @override
  List<Object> get props => [message];
}
