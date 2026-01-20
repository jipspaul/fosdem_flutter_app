import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/map_service.dart';
import '../../../domain/entities/building.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationService locationService;
  final MapService mapService;
  final List<Building> buildings;

  MapBloc({
    required this.locationService,
    required this.mapService,
    this.buildings = const [],
  }) : super(MapInitial()) {
    on<LoadMapData>(_onLoadMapData);
    on<UpdateUserLocation>(_onUpdateUserLocation);
    on<SelectBuilding>(_onSelectBuilding);
    on<ShowEventOnMap>(_onShowEventOnMap);
    on<EnableLocationTracking>(_onEnableLocationTracking);
    on<DisableLocationTracking>(_onDisableLocationTracking);
  }

  Future<void> _onLoadMapData(LoadMapData event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      // For now, use provided buildings or empty list
      // In future, this will load from repository
      emit(MapLoaded(
        buildings: buildings,
        center: MapService.fosdemCenter,
        zoom: MapService.defaultZoom,
      ));
    } catch (e) {
      emit(MapError('Failed to load map data: $e'));
    }
  }

  Future<void> _onUpdateUserLocation(
    UpdateUserLocation event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(userLocation: event.position));
    }
  }

  void _onSelectBuilding(SelectBuilding event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        selectedBuilding: event.building,
        center: event.building.coordinate,
        zoom: 18.0,
      ));
    }
  }

  void _onShowEventOnMap(ShowEventOnMap event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      // Find building with the event's room
      final building = currentState.buildings.isNotEmpty 
        ? currentState.buildings.first 
        : null;
      if (building != null) {
        emit(currentState.copyWith(
          selectedBuilding: building,
          center: building.coordinate,
          zoom: 18.0,
        ));
      }
    }
  }

  Future<void> _onEnableLocationTracking(
    EnableLocationTracking event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        emit(MapError('Location permission denied'));
        return;
      }

      final currentState = state as MapLoaded;
      emit(currentState.copyWith(isTrackingLocation: true));

      // Start watching location
      await emit.forEach(
        locationService.watchLocation(),
        onData: (Position position) {
          if (state is MapLoaded) {
            return (state as MapLoaded).copyWith(
              userLocation: LatLng(position.latitude, position.longitude),
            );
          }
          return state;
        },
        onError: (error, stackTrace) {
          return MapError('Location tracking error: $error');
        },
      );
    }
  }

  void _onDisableLocationTracking(
    DisableLocationTracking event,
    Emitter<MapState> emit,
  ) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(
        isTrackingLocation: false,
        userLocation: null,
      ));
    }
  }
}
