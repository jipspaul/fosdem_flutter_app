import 'package:flutter/material.dart';
import '../../domain/models/journey_models.dart';

class JourneyStatsWidget extends StatelessWidget {
  final JourneyStats stats;

  const JourneyStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.event,
                    label: 'Events',
                    value: '${stats.plannedCount}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.bookmark,
                    label: 'Wishlist',
                    value: '${stats.wishlistCount}',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.directions_walk,
                    label: 'Walking',
                    value: '${stats.totalWalkingTime.inMinutes} min',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.warning,
                    label: 'Conflicts',
                    value: '${stats.conflictCount}',
                    color: stats.conflictCount > 0 
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (stats.totalDistance > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Total distance: ${(stats.totalDistance / 1000).toStringAsFixed(2)} km',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
