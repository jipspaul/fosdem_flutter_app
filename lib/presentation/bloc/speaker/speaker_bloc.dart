import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/person.dart';
import '../../../data/datasources/local/database.dart';

// Events
abstract class SpeakerEvent extends Equatable {
  const SpeakerEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadSpeakersEvent extends SpeakerEvent {
  const LoadSpeakersEvent();
}

// States
abstract class SpeakerState extends Equatable {
  const SpeakerState();
  
  @override
  List<Object?> get props => [];
}

class SpeakerInitial extends SpeakerState {
  const SpeakerInitial();
}

class SpeakerLoadingState extends SpeakerState {
  const SpeakerLoadingState();
}

class SpeakerLoadedState extends SpeakerState {
  final List<Person> speakers;
  
  const SpeakerLoadedState(this.speakers);
  
  @override
  List<Object?> get props => [speakers];
}

class SpeakerErrorState extends SpeakerState {
  final String message;
  
  const SpeakerErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class SpeakerBloc extends Bloc<SpeakerEvent, SpeakerState> {
  final AppDatabase database;
  
  SpeakerBloc({required this.database}) : super(const SpeakerInitial()) {
    on<LoadSpeakersEvent>(_onLoadSpeakers);
  }
  
  Future<void> _onLoadSpeakers(
    LoadSpeakersEvent event,
    Emitter<SpeakerState> emit,
  ) async {
    emit(const SpeakerLoadingState());
    
    try {
      final peopleEntities = await database.peopleDao.getAllPeople();
      final speakers = peopleEntities.map((entity) => Person(
        id: entity.id,
        name: entity.name,
        bio: entity.bio,
        avatar: entity.avatar,
      )).toList();
      
      // Sort by name
      speakers.sort((a, b) => a.name.compareTo(b.name));
      
      emit(SpeakerLoadedState(speakers));
    } catch (e) {
      emit(SpeakerErrorState('Failed to load speakers: $e'));
    }
  }
}
