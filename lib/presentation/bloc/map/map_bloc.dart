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
  final Future<List<Building>> Function()? loadBuildings;

  MapBloc({
    required this.locationService,
    required this.mapService,
    this.loadBuildings,
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
      final buildings = loadBuildings != null
          ? await loadBuildings!()
          : <Building>[];
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
    if (state is! MapLoaded) return;
    try {
      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        final deniedForever =
            await locationService.isPermissionDeniedForever();
        if (deniedForever) {
          emit(MapError(
              'Location was denied. You can enable it in your device Settings.'));
        } else {
          emit(MapError(
              'Location permission denied. Please allow access when prompted.'));
        }
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
    } catch (e) {
      emit(MapError('Location error: $e'));
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
