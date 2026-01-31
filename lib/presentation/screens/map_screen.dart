import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/building.dart';
import '../../domain/entities/event.dart';
import '../../data/services/buildings_service.dart';
import '../../data/datasources/local/database.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/services/location_service.dart';
import '../bloc/favorites/favorites_bloc.dart';
import '../bloc/favorites/favorites_state.dart';
import '../../features/journey/presentation/bloc/journey_bloc.dart';
import '../../features/journey/presentation/bloc/journey_state.dart';
import '../../features/journey/domain/models/journey_models.dart';
import 'event_detail_screen.dart';

/// One "next meeting" entry: from journey (bold) or favorite (grey).
class _NextMeetingItem {
  final JourneyItem item;
  final bool isFromJourney;
  _NextMeetingItem(this.item, {required this.isFromJourney});
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final BuildingsService _buildingsService = BuildingsService();
  late final LocationService _locationService = di.sl<LocationService>();
  List<Building> _buildings = [];
  Building? _selectedBuilding;
  bool _isLoading = true;
  List<Event> _buildingEvents = [];
  bool _loadingEvents = false;
  bool _nextMeetingsExpanded = false;
  LatLng? _userLocation;
  bool _isTrackingLocation = false;
  StreamSubscription<Position>? _locationSubscription;
  /// Route line from current position (or last meeting) to the selected next meeting building.
  List<LatLng>? _routeToMeeting;
  /// When set, destination is highlighted on map but no bottom sheet (itinerary-only mode).
  Building? _destinationBuildingForRoute;
  /// User heading in degrees (0 = north, 90 = east) for the position arrow; null if not available.
  double? _userHeading;

  // FOSDEM location: ULB Campus du Solbosch, Brussels
  static const LatLng fosdemLocation = LatLng(50.8145, 4.3817);
  
  // Brussels city bounds to limit map area and reduce data usage
  static const LatLng brusselsSouthWest = LatLng(50.7967, 4.3466);
  static const LatLng brusselsNorthEast = LatLng(50.9050, 4.4350);

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleLocationTracking() async {
    if (_isTrackingLocation) {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      if (mounted) setState(() { _isTrackingLocation = false; _userLocation = null; _userHeading = null; });
      return;
    }
    final granted = await _locationService.requestLocationPermission();
    if (!granted || !mounted) return;
    setState(() => _isTrackingLocation = true);
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _userHeading = position.heading;
      });
      _mapController.move(_userLocation!, 17.0);
    }
    _locationSubscription = _locationService.watchLocation().listen((Position position) {
      if (mounted) setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _userHeading = position.heading;
      });
    });
  }

  Future<void> _loadBuildings() async {
    try {
      final buildings = await _buildingsService.loadBuildings();
      if (mounted) {
        setState(() {
          _buildings = buildings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading buildings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOSDEM Campus Map'),
        actions: [
          if (_selectedBuilding != null || _destinationBuildingForRoute != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selectedBuilding = null;
                _destinationBuildingForRoute = null;
                _routeToMeeting = null;
              }),
              tooltip: 'Close sheet / clear route',
            ),
          IconButton(
            icon: Icon(_isTrackingLocation ? Icons.location_on : Icons.my_location),
            onPressed: () async {
              if (_isTrackingLocation) {
                await _toggleLocationTracking();
              } else {
                await _toggleLocationTracking();
              }
            },
            tooltip: _isTrackingLocation ? 'Stop GPS' : 'Show my location (GPS)',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 17.0);
              } else {
                _mapController.move(fosdemLocation, 17.0);
              }
            },
            tooltip: 'Center on my location or FOSDEM',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: fosdemLocation,
                    initialZoom: 16.5,
                    minZoom: 15.0,
                    maxZoom: 19.0,
                    // Restrict map to Brussels area to reduce data usage
                    cameraConstraint: CameraConstraint.contain(
                      bounds: LatLngBounds(brusselsSouthWest, brusselsNorthEast),
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onTap: (_, __) => setState(() {
                      _selectedBuilding = null;
                      _destinationBuildingForRoute = null;
                      _routeToMeeting = null;
                    }),
                  ),
                  children: [
                    TileLayer(
                      // Using OpenStreetMap tiles with proper attribution
                      // Note: For production apps, consider using a commercial tile provider
                      // or self-hosting tiles to avoid overloading OSM servers
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fosdem.app',
                      maxZoom: 19,
                      // Only load tiles for Brussels area
                      tileBounds: LatLngBounds(brusselsSouthWest, brusselsNorthEast),
                      tileProvider: NetworkTileProvider(),
                    ),
                    PolygonLayer(
                      polygons: _buildings.map((building) {
                        final isSelected = _selectedBuilding == building || _destinationBuildingForRoute == building;
                        return Polygon(
                          points: building.polygon,
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.5)
                              : Colors.red.withValues(alpha: 0.3),
                          borderColor: isSelected ? Colors.blue : Colors.red,
                          borderStrokeWidth: 2.0,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: _buildings.map((building) {
                        return Marker(
                          point: building.coordinate,
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedBuilding = building);
                              _loadEventsForBuilding(building);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: (_selectedBuilding == building || _destinationBuildingForRoute == building)
                                    ? Colors.blue
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  building.glyph,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: (_selectedBuilding == building || _destinationBuildingForRoute == building)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_userLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation!,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 3),
                              ),
                              child: Transform.rotate(
                                angle: (_userHeading ?? 0) * math.pi / 180,
                                child: const Icon(Icons.navigation, color: Colors.blue, size: 28),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_routeToMeeting != null && _routeToMeeting!.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeToMeeting!,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 5.0,
                          ),
                        ],
                      ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                if (_selectedBuilding != null) _buildBuildingInfo(),
                    ],
                  ),
                ),
                BlocBuilder<JourneyBloc, JourneyState>(
                  builder: (context, journeyState) => _buildNextMeetingsBar(),
                ),
              ],
            ),
      floatingActionButton: _isLoading
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
    );
  }

  Widget _buildBuildingInfo() {
    final building = _selectedBuilding!;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Building ${building.title}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedBuilding = null;
                          _buildingEvents.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Events list
              Expanded(
                child: _loadingEvents
                    ? const Center(child: CircularProgressIndicator())
                    : _buildingEvents.isEmpty
                        ? const Center(
                            child: Text('No events in this building'),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _buildingEvents.length,
                            itemBuilder: (context, index) {
                              final event = _buildingEvents[index];
                              return BlocBuilder<JourneyBloc, JourneyState>(
                                buildWhen: (prev, curr) => prev != curr,
                                builder: (context, journeyCtx) {
                                  return BlocBuilder<FavoritesBloc, FavoritesState>(
                                    builder: (context, favState) {
                                      final isOnTimeline = journeyCtx is JourneyLoaded &&
                                          (journeyCtx.planned.any((i) => i.eventId == event.id) ||
                                              journeyCtx.wishlist.any((i) => i.eventId == event.id));
                                      final isFavorite = favState is FavoritesLoaded &&
                                          favState.isFavorite(event.id.toString());

                                      IconData leadingIcon = Icons.event;
                                      Color? leadingColor;
                                      if (isOnTimeline) {
                                        leadingIcon = Icons.event_available;
                                        leadingColor = Colors.green;
                                      } else if (isFavorite) {
                                        leadingIcon = Icons.favorite;
                                        leadingColor = Colors.red;
                                      }

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          leading: Icon(leadingIcon, color: leadingColor),
                                      title: Text(
                                        event.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_formatTime(event.start)} - ${event.room}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            event.track,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => EventDetailScreen(event: event),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Next 30 min (max 5); if none, then next 5 upcoming from journey + favorites.
  List<_NextMeetingItem> _computeNextMeetings() {
    final journeyState = context.read<JourneyBloc>().state;
    if (journeyState is! JourneyLoaded) return [];
    final now = DateTime.now();
    final endWindow30 = now.add(const Duration(minutes: 30));
    final plannedIn30 = journeyState.planned
        .where((i) =>
            !i.startTime.isBefore(now) && i.startTime.isBefore(endWindow30))
        .map((i) => _NextMeetingItem(i, isFromJourney: true));
    final candidatesIn30 = journeyState.candidates
        .where((i) =>
            !i.startTime.isBefore(now) && i.startTime.isBefore(endWindow30))
        .map((i) => _NextMeetingItem(i, isFromJourney: false));
    var combined = <_NextMeetingItem>[...plannedIn30, ...candidatesIn30]
      ..sort((a, b) => a.item.startTime.compareTo(b.item.startTime));
    if (combined.isEmpty) {
      final plannedUpcoming = journeyState.planned
          .where((i) => !i.startTime.isBefore(now))
          .map((i) => _NextMeetingItem(i, isFromJourney: true));
      final candidatesUpcoming = journeyState.candidates
          .where((i) => !i.startTime.isBefore(now))
          .map((i) => _NextMeetingItem(i, isFromJourney: false));
      combined = <_NextMeetingItem>[...plannedUpcoming, ...candidatesUpcoming]
        ..sort((a, b) => a.item.startTime.compareTo(b.item.startTime));
    }
    return combined.take(5).toList();
  }

  Building? _buildingForJourneyItem(String buildingId) {
    final upper = buildingId.toUpperCase();
    try {
      return _buildings.firstWhere((b) =>
          b.title.toUpperCase() == upper ||
          b.title.toUpperCase().startsWith(upper) ||
          upper.startsWith(b.title.toUpperCase()));
    } catch (_) {
      return null;
    }
  }

  /// Start point for itinerary: user location, or last meeting on journey, or FOSDEM center.
  LatLng _routeFromPoint() {
    if (_userLocation != null) return _userLocation!;
    final journeyState = context.read<JourneyBloc>().state;
    if (journeyState is JourneyLoaded && journeyState.planned.isNotEmpty) {
      final now = DateTime.now();
      final pastOrCurrent = journeyState.planned
          .where((i) =>
              i.endTime.isBefore(now) ||
              (i.startTime.isBefore(now) && i.endTime.isAfter(now)))
          .toList();
      if (pastOrCurrent.isNotEmpty) {
        pastOrCurrent.sort((a, b) => b.endTime.compareTo(a.endTime));
        return pastOrCurrent.first.location;
      }
    }
    return fosdemLocation;
  }

  Widget _buildNextMeetingsBar() {
    final nextMeetings = _computeNextMeetings();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _nextMeetingsExpanded = !_nextMeetingsExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Go to next meeting',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (nextMeetings.isNotEmpty)
                      Text(
                        ' (${nextMeetings.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    const Spacer(),
                    Icon(
                      _nextMeetingsExpanded
                          ? Icons.expand_more
                          : Icons.expand_less,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_nextMeetingsExpanded && nextMeetings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No upcoming meetings. Add events to your journey or favorites.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_nextMeetingsExpanded && nextMeetings.isNotEmpty)
            ...nextMeetings.map((m) {
              final timeStr =
                  '${m.item.startTime.hour.toString().padLeft(2, '0')}:${m.item.startTime.minute.toString().padLeft(2, '0')}';
              return ListTile(
                dense: true,
                leading: Icon(
                  m.isFromJourney ? Icons.route : Icons.favorite_border,
                  size: 20,
                  color: m.isFromJourney
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                title: Text(
                  m.item.eventTitle,
                  style: m.isFromJourney
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$timeStr · ${m.item.room}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  final building =
                      _buildingForJourneyItem(m.item.building);
                  if (building != null) {
                    final from = _routeFromPoint();
                    final to = building.coordinate;
                    setState(() {
                      _selectedBuilding = null;
                      _buildingEvents = [];
                      _destinationBuildingForRoute = building;
                      _routeToMeeting = [from, to];
                    });
                    // Center map to show route; bottom sheet stays closed so map is visible
                    final midLat = (from.latitude + to.latitude) / 2;
                    final midLng = (from.longitude + to.longitude) / 2;
                    _mapController.move(LatLng(midLat, midLng), 16.5);
                  }
                },
              );
            }),
        ],
      ),
    );
  }

  Future<void> _loadEventsForBuilding(Building building) async {
    setState(() {
      _loadingEvents = true;
      _buildingEvents.clear();
    });

    try {
      // Get database from service locator instead of context
      final database = di.sl<AppDatabase>();
      final allEvents = await database.eventsDao.getAllEvents();
      
      // Convert EventEntity to Event and filter by building
      final buildingPrefix = building.title.toUpperCase();
      final firstLetter = buildingPrefix.isNotEmpty ? buildingPrefix.substring(0, 1) : '';
      final eventsInBuilding = allEvents
          .where((eventEntity) {
            // Check if room starts with building name or first letter (e.g. "J.1.105" for "Janson")
            final room = eventEntity.room.toUpperCase();
            return room.startsWith('$buildingPrefix.') ||
                   room.startsWith(buildingPrefix) ||
                   room == buildingPrefix ||
                   room.startsWith('$firstLetter.') ||
                   room == firstLetter;
          })
          .map((eventEntity) => Event(
                id: eventEntity.id,
                title: eventEntity.title,
                subtitle: eventEntity.subtitle,
                abstract: eventEntity.abstract,
                description: eventEntity.description,
                start: eventEntity.start,
                date: eventEntity.start,
                duration: eventEntity.duration,
                room: eventEntity.room,
                track: eventEntity.track,
                url: eventEntity.url,
                people: const [],
                links: const [],
                attachments: const [],
                isSync: false,
              ))
          .where((event) => !event.isPast())
          .toList();

      // Event IDs on my timeline (planned + wishlist)
      final journeyBloc = context.read<JourneyBloc>();
      final journeyState = journeyBloc.state;
      final Set<int> timelineEventIds = {};
      if (journeyState is JourneyLoaded) {
        timelineEventIds.addAll(journeyState.planned.map((i) => i.eventId));
        timelineEventIds.addAll(journeyState.wishlist.map((i) => i.eventId));
      }

      final favoritesBloc = context.read<FavoritesBloc>();
      final favoritesState = favoritesBloc.state;

      // Sort: 1) on my timeline, 2) favorites, 3) rest; then by start time
      eventsInBuilding.sort((a, b) {
        final aOnTimeline = timelineEventIds.contains(a.id);
        final bOnTimeline = timelineEventIds.contains(b.id);
        final aIsFavorite = favoritesState is FavoritesLoaded &&
            favoritesState.isFavorite(a.id.toString());
        final bIsFavorite = favoritesState is FavoritesLoaded &&
            favoritesState.isFavorite(b.id.toString());

        if (aOnTimeline && !bOnTimeline) return -1;
        if (!aOnTimeline && bOnTimeline) return 1;
        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;
        return a.start.compareTo(b.start);
      });

      if (mounted) {
        setState(() {
          _buildingEvents = eventsInBuilding;
          _loadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading events for building: $e');
      if (mounted) {
        setState(() {
          _loadingEvents = false;
        });
      }
    }
  }
}
