import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/map/map_bloc.dart';
import '../../widgets/map/fosdem_map_widget.dart';
import '../../../domain/entities/building.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<MapBloc>()..add(LoadMapData()),
      child: Scaffold(
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
              return Column(
                children: [
                  Expanded(
                    child: FosdemMapWidget(
                      center: state.center,
                      zoom: state.zoom,
                      buildings: state.buildings,
                      selectedBuilding: state.selectedBuilding,
                      userLocation: state.userLocation,
                      onBuildingTap: (building) {
                        context.read<MapBloc>().add(SelectBuilding(building));
                        _showBuildingInfo(context, building);
                      },
                      onLocationButtonPressed: () {
                        if (!state.isTrackingLocation) {
                          context.read<MapBloc>().add(EnableLocationTracking());
                        }
                      },
                    ),
                  ),
                  if (state.selectedBuilding != null)
                    _BuildingInfoBar(building: state.selectedBuilding!),
                ],
              );
            }

            return const Center(child: Text('Map not available'));
          },
        ),
      ),
    );
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
