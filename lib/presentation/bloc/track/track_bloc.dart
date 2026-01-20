import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/track.dart';
import '../../../domain/repositories/tracks_repository.dart';

// Events
abstract class TrackEvent extends Equatable {
  const TrackEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadTracksEvent extends TrackEvent {
  const LoadTracksEvent();
}

// States
abstract class TrackState extends Equatable {
  const TrackState();
  
  @override
  List<Object?> get props => [];
}

class TrackInitial extends TrackState {
  const TrackInitial();
}

class TrackLoadingState extends TrackState {
  const TrackLoadingState();
}

class TrackLoadedState extends TrackState {
  final List<Track> tracks;
  
  const TrackLoadedState(this.tracks);
  
  @override
  List<Object?> get props => [tracks];
}

class TrackErrorState extends TrackState {
  final String message;
  
  const TrackErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class TrackBloc extends Bloc<TrackEvent, TrackState> {
  final TracksRepository tracksRepository;
  
  TrackBloc({required this.tracksRepository}) : super(const TrackInitial()) {
    on<LoadTracksEvent>(_onLoadTracks);
  }
  
  Future<void> _onLoadTracks(
    LoadTracksEvent event,
    Emitter<TrackState> emit,
  ) async {
    emit(const TrackLoadingState());
    
    try {
      final result = await tracksRepository.getTracks();
      
      result.fold(
        (failure) => emit(TrackErrorState('Failed to load tracks: ${failure.message}')),
        (tracks) {
          // Sort by name
          final sortedTracks = List<Track>.from(tracks)..sort((a, b) => a.name.compareTo(b.name));
          emit(TrackLoadedState(sortedTracks));
        },
      );
    } catch (e) {
      emit(TrackErrorState('Failed to load tracks: $e'));
    }
  }
}
