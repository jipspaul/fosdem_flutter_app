import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../bloc/map/map_bloc.dart';
import '../../widgets/map/fosdem_map_widget.dart';
import '../../../domain/entities/building.dart';
import '../../../core/services/map_service.dart';
import '../../../features/journey/presentation/bloc/journey_bloc.dart';
import '../../../features/journey/presentation/bloc/journey_state.dart';
import '../../../features/journey/domain/models/journey_models.dart';

/// One "next meeting" entry: either from journey (bold) or favorite (grey).
class _NextMeeting {
  final JourneyItem item;
  final bool isFromJourney; // true = journey (bold), false = favorite (grey)

  _NextMeeting(this.item, {required this.isFromJourney});
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _loadDataDispatched = false;
  bool _nextMeetingsExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On iOS, request location and enable GPS tracking when map is opened
    if (!_loadDataDispatched && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _loadDataDispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<MapBloc>().add(EnableLocationTracking());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOSDEM Campus Map'),
        actions: [
          BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              if (state is MapLoaded) {
                return IconButton(
                  icon: Icon(
                    state.isTrackingLocation
                        ? Icons.location_on
                        : Icons.location_off,
                  ),
                  onPressed: () {
                    if (state.isTrackingLocation) {
                      context.read<MapBloc>().add(DisableLocationTracking());
                    } else {
                      context.read<MapBloc>().add(EnableLocationTracking());
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MapBloc>().add(LoadMapData());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is MapLoaded) {
            final nextMeetings = _computeNextMeetings(context);
            final routePolylines = _computeRoutePolylines(
              context,
              state.userLocation,
              nextMeetings,
            );
            return Column(
              children: [
                Expanded(
                  child: FosdemMapWidget(
                    center: state.center,
                    zoom: state.zoom,
                    buildings: state.buildings,
                    selectedBuilding: state.selectedBuilding,
                    userLocation: state.userLocation,
                    routePolylines: routePolylines,
                    onBuildingTap: (building) {
                      context.read<MapBloc>().add(SelectBuilding(building));
                      _showBuildingInfo(context, building);
                    },
                    onLocationButtonPressed: () {
                      if (!state.isTrackingLocation) {
                        context
                            .read<MapBloc>()
                            .add(EnableLocationTracking());
                      }
                    },
                  ),
                ),
                _NextMeetingsBar(
                  nextMeetings: nextMeetings,
                  expanded: _nextMeetingsExpanded,
                  onToggle: () {
                    setState(() {
                      _nextMeetingsExpanded = !_nextMeetingsExpanded;
                    });
                  },
                  onMeetingTap: (item) {
                    final building =
                        _buildingForItem(state.buildings, item.item);
                    if (building != null) {
                      context.read<MapBloc>().add(SelectBuilding(building));
                      _showBuildingInfo(context, building);
                    }
                  },
                ),
                if (state.selectedBuilding != null)
                  _BuildingInfoBar(building: state.selectedBuilding!),
              ],
            );
          }

          return const Center(child: Text('Map not available'));
        },
      ),
    );
  }

  /// Next 30 min, max 5: journey (planned) in bold, favorites (candidates) in grey.
  List<_NextMeeting> _computeNextMeetings(BuildContext context) {
    final journeyState = context.read<JourneyBloc>().state;
    if (journeyState is! JourneyLoaded) return [];

    final now = DateTime.now();
    final endWindow = now.add(const Duration(minutes: 30));
    final plannedInWindow = journeyState.planned
        .where((i) =>
            !i.startTime.isBefore(now) && i.startTime.isBefore(endWindow))
        .map((i) => _NextMeeting(i, isFromJourney: true))
        .toList();
    final candidatesInWindow = journeyState.candidates
        .where((i) =>
            !i.startTime.isBefore(now) && i.startTime.isBefore(endWindow))
        .map((i) => _NextMeeting(i, isFromJourney: false))
        .toList();
    final combined = <_NextMeeting>[...plannedInWindow, ...candidatesInWindow]
      ..sort((a, b) => a.item.startTime.compareTo(b.item.startTime));
    return combined.take(5).toList();
  }

  List<MapRoutePolyline> _computeRoutePolylines(
    BuildContext context,
    LatLng? userLocation,
    List<_NextMeeting> nextMeetings,
  ) {
    if (nextMeetings.isEmpty) return [];
    final mapState = context.read<MapBloc>().state;
    if (mapState is! MapLoaded) return [];

    LatLng from = userLocation ?? MapService.fosdemCenter;
    // If we have journey planned, use last meeting (by end time) before "now" as from
    final journeyState = context.read<JourneyBloc>().state;
    if (journeyState is JourneyLoaded && journeyState.planned.isNotEmpty) {
      final pastOrCurrent = journeyState.planned
          .where((i) => i.endTime.isBefore(DateTime.now()) ||
              (i.startTime.isBefore(DateTime.now()) && i.endTime.isAfter(DateTime.now())))
          .toList();
      if (pastOrCurrent.isNotEmpty) {
        pastOrCurrent.sort((a, b) => b.endTime.compareTo(a.endTime));
        from = pastOrCurrent.first.location;
      }
    }

    return nextMeetings
        .map((m) => MapRoutePolyline(
              points: [from, m.item.location],
              isBold: m.isFromJourney,
            ))
        .toList();
  }

  Building? _buildingForItem(List<Building> buildings, JourneyItem item) {
    final buildingId = item.building;
    try {
      return buildings.firstWhere(
        (b) => b.id == buildingId || b.title == buildingId,
      );
    } catch (_) {
      return null;
    }
  }

  void _showBuildingInfo(BuildContext context, Building building) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              building.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Building ID: ${building.id}'),
            if (building.hasBlueprints)
              Text('Blueprints: ${building.blueprints.length}'),
          ],
        ),
      ),
    );
  }
}

class _NextMeetingsBar extends StatelessWidget {
  final List<_NextMeeting> nextMeetings;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(_NextMeeting) onMeetingTap;

  const _NextMeetingsBar({
    required this.nextMeetings,
    required this.expanded,
    required this.onToggle,
    required this.onMeetingTap,
  });

  @override
  Widget build(BuildContext context) {
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
              onTap: nextMeetings.isEmpty ? null : onToggle,
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
                    if (nextMeetings.isNotEmpty)
                      Icon(
                        expanded ? Icons.expand_more : Icons.expand_less,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded && nextMeetings.isNotEmpty)
            ...nextMeetings.map((m) {
              final style = m.isFromJourney
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )
                  : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      );
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
                  style: style,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$timeStr · ${m.item.room}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => onMeetingTap(m),
              );
            }),
        ],
      ),
    );
  }
}

class _BuildingInfoBar extends StatelessWidget {
  final Building building;

  const _BuildingInfoBar({required this.building});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(building.glyph),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  building.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'ID: ${building.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(building.title),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Building ID: ${building.id}'),
                      if (building.hasBlueprints)
                        Text('Blueprints: ${building.blueprints.length}'),
                      if (building.hasPolygon)
                        Text('Polygon points: ${building.polygon.length}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
