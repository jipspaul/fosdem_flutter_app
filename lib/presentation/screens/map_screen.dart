import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/building.dart';
import '../../domain/entities/event.dart';
import '../../data/services/buildings_service.dart';
import '../../data/datasources/local/database.dart';
import '../../core/di/injection_container.dart' as di;
import '../bloc/favorites/favorites_bloc.dart';
import '../bloc/favorites/favorites_state.dart';
import 'event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final BuildingsService _buildingsService = BuildingsService();
  List<Building> _buildings = [];
  Building? _selectedBuilding;
  bool _isLoading = true;
  List<Event> _buildingEvents = [];
  bool _loadingEvents = false;

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
          if (_selectedBuilding != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedBuilding = null),
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(fosdemLocation, 17.0);
            },
            tooltip: 'Center on FOSDEM',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                    onTap: (_, __) => setState(() => _selectedBuilding = null),
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
                        final isSelected = _selectedBuilding == building;
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
                                color: _selectedBuilding == building
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
                                    color: _selectedBuilding == building
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
                              return BlocBuilder<FavoritesBloc, FavoritesState>(
                                builder: (context, favState) {
                                  final isFavorite = favState is FavoritesLoaded &&
                                      favState.isFavorite(event.id.toString());
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: isFavorite
                                          ? const Icon(Icons.favorite, color: Colors.red)
                                          : const Icon(Icons.event),
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
      
      final eventsInBuilding = allEvents
          .where((eventEntity) {
            // Check if room starts with building name
            // e.g., "K.1.105" starts with "K"
            final room = eventEntity.room.toUpperCase();
            return room.startsWith('$buildingPrefix.') || 
                   room.startsWith(buildingPrefix) ||
                   room == buildingPrefix;
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
          .toList();

      // Get favorites state
      final favoritesBloc = context.read<FavoritesBloc>();
      final favoritesState = favoritesBloc.state;
      
      // Sort: favorites first, then by date/time
      eventsInBuilding.sort((a, b) {
        if (favoritesState is FavoritesLoaded) {
          final aIsFavorite = favoritesState.isFavorite(a.id.toString());
          final bIsFavorite = favoritesState.isFavorite(b.id.toString());
          
          // Favorites first
          if (aIsFavorite && !bIsFavorite) return -1;
          if (!aIsFavorite && bIsFavorite) return 1;
        }
        
        // Then by date/time
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
