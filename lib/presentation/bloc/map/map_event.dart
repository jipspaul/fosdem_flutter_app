part of 'map_bloc.dart';

abstract class MapEvent {}

class LoadMapData extends MapEvent {}

class UpdateUserLocation extends MapEvent {
  final LatLng position;
  UpdateUserLocation(this.position);
}

class SelectBuilding extends MapEvent {
  final Building building;
  SelectBuilding(this.building);
}

class ShowEventOnMap extends MapEvent {
  final String room;
  ShowEventOnMap(this.room);
}

class EnableLocationTracking extends MapEvent {}

class DisableLocationTracking extends MapEvent {}
