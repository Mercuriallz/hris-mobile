import 'package:equatable/equatable.dart';

import '../model/warning_letter_model.dart';

abstract class WarningLetterState extends Equatable {
  @override
  List<Object> get props => [];
}

class WarningLetterInitial extends WarningLetterState {}

class WarningLetterLoading extends WarningLetterState {}

class WarningLetterLoaded extends WarningLetterState {
  final List<WarningLetter> letters;

  WarningLetterLoaded(this.letters);

  @override
  List<Object> get props => [letters.map((l) => '${l.id}:${l.status}:${l.isUnread}').join(',')];
}

class WarningLetterError extends WarningLetterState {
  final String message;

  WarningLetterError(this.message);

  @override
  List<Object> get props => [message];
}
