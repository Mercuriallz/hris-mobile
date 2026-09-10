import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String message;

  LoginSuccess(this.message);

  @override
  List<Object> get props => [message];
}


class LoginMustChangePassword extends LoginState {
  final String message;

  LoginMustChangePassword(this.message);

  @override
  List<Object> get props => [message];
}

class LoginError extends LoginState {
  final String message;


  LoginError(this.message);

  @override
  List<Object> get props => [message];
}
