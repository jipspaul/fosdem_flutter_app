import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/core/services/location_service.dart';
import 'package:fosdem_flutter/core/services/map_service.dart';
import 'package:fosdem_flutter/domain/entities/building.dart';
import 'package:fosdem_flutter/presentation/bloc/map/map_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';

@GenerateMocks([LocationService, MapService])
import 'map_bloc_test.mocks.dart';

void main() {
  group('MapBloc', () {
    late MockLocationService mockLocationService;
    late MockMapService mockMapService;
    late List<Building> testBuildings;

    setUp(() {
      mockLocationService = MockLocationService();
      mockMapService = MockMapService();
      
      testBuildings = [
        const Building(
          id: 'H',
          title: 'H Building',
          glyph: 'H',
          coordinate: LatLng(50.812, 4.381),
          polygon: [
            LatLng(50.812, 4.381),
            LatLng(50.813, 4.381),
            LatLng(50.813, 4.382),
            LatLng(50.812, 4.382),
          ],
        ),
        const Building(
          id: 'K',
          title: 'K Building',
          glyph: 'K',
          coordinate: LatLng(50.813, 4.383),
          polygon: [
            LatLng(50.813, 4.383),
            LatLng(50.814, 4.383),
            LatLng(50.814, 4.384),
            LatLng(50.813, 4.384),
          ],
        ),
      ];
    });

    blocTest<MapBloc, MapState>(
      'emits [MapLoading, MapLoaded] when LoadMapData is added',
      build: () => MapBloc(
        locationService: mockLocationService,
        mapService: mockMapService,
        buildings: testBuildings,
      ),
      act: (bloc) => bloc.add(LoadMapData()),
      expect: () => [
        isA<MapLoading>(),
        isA<MapLoaded>()
          .having((state) => state.buildings.length, 'buildings count', 2)
          .having((state) => state.center, 'center', MapService.fosdemCenter)
          .having((state) => state.zoom, 'zoom', MapService.defaultZoom),
      ],
    );

    blocTest<MapBloc, MapState>(
      'emits updated state when SelectBuilding is added',
      build: () => MapBloc(
        locationService: mockLocationService,
        mapService: mockMapService,
        buildings: testBuildings,
      ),
      seed: () => MapLoaded(
        buildings: testBuildings,
        center: MapService.fosdemCenter,
        zoom: MapService.defaultZoom,
      ),
      act: (bloc) => bloc.add(SelectBuilding(testBuildings.first)),
      expect: () => [
        isA<MapLoaded>()
          .having((state) => state.selectedBuilding, 'selected building', testBuildings.first)
          .having((state) => state.center, 'center', testBuildings.first.coordinate)
          .having((state) => state.zoom, 'zoom', 18.0),
      ],
    );

    blocTest<MapBloc, MapState>(
      'emits updated state when UpdateUserLocation is added',
      build: () => MapBloc(
        locationService: mockLocationService,
        mapService: mockMapService,
        buildings: testBuildings,
      ),
      seed: () => MapLoaded(
        buildings: testBuildings,
        center: MapService.fosdemCenter,
        zoom: MapService.defaultZoom,
      ),
      act: (bloc) => bloc.add(UpdateUserLocation(const LatLng(50.812, 4.381))),
      expect: () => [
        isA<MapLoaded>()
          .having((state) => state.userLocation, 'user location', const LatLng(50.812, 4.381)),
      ],
    );

    blocTest<MapBloc, MapState>(
      'disables location tracking when DisableLocationTracking is added',
      build: () => MapBloc(
        locationService: mockLocationService,
        mapService: mockMapService,
        buildings: testBuildings,
      ),
      seed: () => MapLoaded(
        buildings: testBuildings,
        center: MapService.fosdemCenter,
        zoom: MapService.defaultZoom,
        isTrackingLocation: true,
        userLocation: const LatLng(50.812, 4.381),
      ),
      act: (bloc) => bloc.add(DisableLocationTracking()),
      expect: () => [
        isA<MapLoaded>()
          .having((state) => state.isTrackingLocation, 'is tracking', false)
          .having((state) => state.userLocation, 'user location', null),
      ],
    );

    blocTest<MapBloc, MapState>(
      'shows event on map when ShowEventOnMap is added',
      build: () => MapBloc(
        locationService: mockLocationService,
        mapService: mockMapService,
        buildings: testBuildings,
      ),
      seed: () => MapLoaded(
        buildings: testBuildings,
        center: MapService.fosdemCenter,
        zoom: MapService.defaultZoom,
      ),
      act: (bloc) => bloc.add(ShowEventOnMap('H.2215')),
      expect: () => [
        isA<MapLoaded>()
          .having((state) => state.selectedBuilding, 'selected building', testBuildings.first)
          .having((state) => state.zoom, 'zoom', 18.0),
      ],
    );
  });
}
