import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/building.dart';

/// A single path segment to draw on the map (e.g. to next meeting).
class MapRoutePolyline {
  final List<LatLng> points;
  final bool isBold; // true = journey (bold), false = favorite (grey)

  const MapRoutePolyline({required this.points, this.isBold = true});
}

class FosdemMapWidget extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final List<Building> buildings;
  final Building? selectedBuilding;
  final LatLng? userLocation;
  final List<MapRoutePolyline> routePolylines;
  final Function(Building)? onBuildingTap;
  final VoidCallback? onLocationButtonPressed;
  final bool showLocationButton;

  const FosdemMapWidget({
    super.key,
    required this.center,
    required this.zoom,
    required this.buildings,
    this.selectedBuilding,
    this.userLocation,
    this.routePolylines = const [],
    this.onBuildingTap,
    this.onLocationButtonPressed,
    this.showLocationButton = true,
  });

  @override
  State<FosdemMapWidget> createState() => _FosdemMapWidgetState();
}

class _FosdemMapWidgetState extends State<FosdemMapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(FosdemMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center || oldWidget.zoom != widget.zoom) {
      _mapController.move(widget.center, widget.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            minZoom: 12.0,
            maxZoom: 19.0,
            onTap: (tapPosition, point) => _handleMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fosdem.app',
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade200,
                    BlendMode.saturation,
                  ),
                  child: tileWidget,
                );
              },
            ),
            if (widget.buildings.isNotEmpty)
              PolygonLayer(
                polygons: widget.buildings
                    .where((b) => b.hasPolygon)
                    .map((building) {
                  final isSelected = building == widget.selectedBuilding;
                  return Polygon(
                    points: building.polygon,
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.2),
                    borderColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.blue,
                    borderStrokeWidth: isSelected ? 3.0 : 2.0,
                  );
                }).toList(),
              ),
            if (widget.buildings.isNotEmpty)
              MarkerLayer(
                markers: widget.buildings.map((building) {
                  final isSelected = building == widget.selectedBuilding;
                  return Marker(
                    point: building.coordinate,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => widget.onBuildingTap?.call(building),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (widget.userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.userLocation!,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            if (widget.routePolylines.isNotEmpty)
              PolylineLayer(
                polylines: widget.routePolylines.map((r) {
                  return Polyline(
                    points: r.points,
                    color: r.isBold
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    strokeWidth: r.isBold ? 5.0 : 3.0,
                  );
                }).toList(),
              ),
          ],
        ),
        if (widget.showLocationButton)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              mini: true,
              onPressed: widget.onLocationButtonPressed,
              child: const Icon(Icons.my_location),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 150,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_in',
                onPressed: () {
                  final newZoom = (_mapController.camera.zoom + 1).clamp(12.0, 19.0);
                  _mapController.move(_mapController.camera.center, newZoom);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_out',
                onPressed: () {
                  final newZoom = (_mapController.camera.zoom - 1).clamp(12.0, 19.0);
                  _mapController.move(_mapController.camera.center, newZoom);
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMapTap(LatLng point) {
    // Check if tapped on any building polygon
    for (final building in widget.buildings) {
      if (building.containsPoint(point)) {
        widget.onBuildingTap?.call(building);
        return;
      }
    }
  }
}
