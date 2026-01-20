import 'package:equatable/equatable.dart';

abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

class LoadingState extends BaseState {
  const LoadingState();
}

class ErrorState extends BaseState {
  final String message;
  final String? errorCode;
  final dynamic error;

  const ErrorState({
    required this.message,
    this.errorCode,
    this.error,
  });

  @override
  List<Object?> get props => [message, errorCode, error];
}
