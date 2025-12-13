import 'package:equatable/equatable.dart';

class FailureEntity extends Equatable {
  final String message;
  final String? code;

  const FailureEntity(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}