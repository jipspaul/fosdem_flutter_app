import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_event.dart';
import 'base_state.dart';

abstract class BaseBloc<E extends BaseEvent, S extends BaseState>
    extends Bloc<E, S> {
  BaseBloc(super.initialState);

  void logEvent(E event) {
    print('[${runtimeType}] Event: $event');
  }

  void logState(S state) {
    print('[${runtimeType}] State: $state');
  }

  void logError(dynamic error, StackTrace stackTrace) {
    print('[${runtimeType}] Error: $error');
    print('[${runtimeType}] StackTrace: $stackTrace');
  }

  @override
  void onEvent(E event) {
    super.onEvent(event);
    logEvent(event);
  }

  @override
  void onChange(Change<S> change) {
    super.onChange(change);
    logState(change.nextState);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    logError(error, stackTrace);
    super.onError(error, stackTrace);
  }

  Future<void> handleError(
    Emitter<S> emit,
    dynamic error,
    StackTrace stackTrace,
  ) async {
    logError(error, stackTrace);
  }
}
