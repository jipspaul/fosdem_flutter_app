import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/event_discovery_bloc.dart';
import '../bloc/event_discovery_event.dart';
import '../bloc/event_discovery_state.dart';
import '../widgets/swipeable_event_card.dart';
import '../../../../presentation/bloc/favorites/favorites_bloc.dart';
import '../../../../presentation/bloc/favorites/favorites_event.dart';

class EventDiscoveryScreen extends StatelessWidget {
  const EventDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the global EventDiscoveryBloc instance
    // Ensure we load the next event when the screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventDiscoveryBloc>().add(LoadNextEvent());
    });
    
    return const EventDiscoveryView();
  }
}

class EventDiscoveryView extends StatelessWidget {
  const EventDiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showResetDialog(context);
            },
            tooltip: 'Reset Discovery',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInstructions(context);
            },
            tooltip: 'How to use',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<EventDiscoveryBloc, EventDiscoveryState>(
          builder: (context, state) {
            if (state is EventDiscoveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventDiscoveryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<EventDiscoveryBloc>().add(LoadNextEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state is EventDiscoveryEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<EventDiscoveryBloc>().add(ResetDiscovery());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Start Over'),
                  ),
                ],
              ),
            );
          }

          if (state is EventDiscoveryLoaded) {
            return Column(
              children: [
                // Progress indicator
                _buildProgressBar(state),

                // Stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        context,
                        'Seen',
                        state.totalSeen.toString(),
                        Icons.visibility,
                      ),
                      _buildStat(
                        context,
                        'Remaining',
                        state.remainingCount.toString(),
                        Icons.schedule,
                      ),
                    ],
                  ),
                ),

                // Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SwipeableEventCard(
                      event: state.currentEvent,
                      onSwipeLeft: () {
                        context.read<EventDiscoveryBloc>().add(
                              SwipeLeft(state.currentEvent.id.toString()),
                            );
                      },
                      onSwipeRight: () {
                        // Add to favorites - use AddFavorite not Toggle
                        context.read<FavoritesBloc>().add(
                              AddFavorite(state.currentEvent.id.toString()),
                            );
                        // Record swipe in discovery bloc
                        context.read<EventDiscoveryBloc>().add(
                              SwipeRight(state.currentEvent.id.toString()),
                            );
                      },
                      onSkip: () {
                        context.read<EventDiscoveryBloc>().add(
                              SkipEvent(state.currentEvent.id.toString()),
                            );
                      },
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(context, state),
              ],
            );
          }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar(EventDiscoveryLoaded state) {
    final total = state.totalSeen + state.remainingCount + 1;
    final progress = state.totalSeen / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% complete',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, EventDiscoveryLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike button
          FloatingActionButton.large(
            heroTag: 'dislike',
            backgroundColor: Colors.red,
            onPressed: () {
              context.read<EventDiscoveryBloc>().add(
                    SwipeLeft(state.currentEvent.id.toString()),
                  );
            },
            child: const Icon(Icons.close, size: 32, color: Colors.white),
          ),

          // Skip button
          FloatingActionButton(
            heroTag: 'skip',
            backgroundColor: Colors.grey[300],
            onPressed: () {
              context.read<EventDiscoveryBloc>().add(
                    SkipEvent(state.currentEvent.id.toString()),
                  );
            },
            child: Icon(Icons.skip_next, color: Colors.grey[700]),
          ),

          // Like button
          FloatingActionButton.large(
            heroTag: 'like',
            backgroundColor: Colors.green,
            onPressed: () {
              context.read<EventDiscoveryBloc>().add(
                    SwipeRight(state.currentEvent.id.toString()),
                  );
            },
            child: const Icon(Icons.favorite, size: 32, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👆 Swipe or tap buttons to choose:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Swipe right or tap ❤️ to add to favorites')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.close, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Swipe left or tap ✖️ to pass')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.skip_next, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(child: Text('Tap ⏭️ to skip (see later)')),
              ],
            ),
            SizedBox(height: 12),
            Text('Events are shown in random order. Your progress is saved!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Discovery?'),
        content: const Text(
          'This will clear your swipe history and let you see all events again. Your favorites will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<EventDiscoveryBloc>().add(ResetDiscovery());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
