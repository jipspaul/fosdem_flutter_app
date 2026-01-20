part of 'map_bloc.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<Building> buildings;
  final LatLng center;
  final double zoom;
  final Building? selectedBuilding;
  final LatLng? userLocation;
  final bool isTrackingLocation;

  MapLoaded({
    required this.buildings,
    required this.center,
    required this.zoom,
    this.selectedBuilding,
    this.userLocation,
    this.isTrackingLocation = false,
  });

  MapLoaded copyWith({
    List<Building>? buildings,
    LatLng? center,
    double? zoom,
    Building? selectedBuilding,
    LatLng? userLocation,
    bool? isTrackingLocation,
  }) {
    return MapLoaded(
      buildings: buildings ?? this.buildings,
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      selectedBuilding: selectedBuilding ?? this.selectedBuilding,
      userLocation: userLocation ?? this.userLocation,
      isTrackingLocation: isTrackingLocation ?? this.isTrackingLocation,
    );
  }
}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}
