import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/event.dart';
import '../../../favorites/bloc/favorites_bloc.dart';
import '../../../../presentation/bloc/event_detail/event_detail_bloc.dart';
import '../../../../presentation/bloc/event_detail/event_detail_event.dart';
import '../../../../presentation/bloc/event_detail/event_detail_state.dart';

class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({
    super.key,
    required this.event,
  }) : super();

  @override
  Widget build(BuildContext context) {
    // Trigger loading event details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventDetailBloc>().add(LoadEventDetail(event.url, event.id, event.title));
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, state) {
              final isFavorite = state is FavoritesLoaded &&
                  state.favoriteEventIds.contains(event.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: () {
                  if (isFavorite) {
                    context.read<FavoritesBloc>().add(
                          RemoveFavoriteEvent(event.id),
                        );
                  } else {
                    context.read<FavoritesBloc>().add(
                          AddFavoriteEvent(event.id),
                        );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<EventDetailBloc, EventDetailState>(
        builder: (context, state) {
          // Debug info at top
          String debugInfo = 'State: ${state.runtimeType}\n';
          debugInfo += 'Event URL: ${event.url ?? "NULL"}\n';
          debugInfo += 'Event ID: ${event.id}\n';
          
          if (state is EventDetailLoading) {
            return Column(
              children: [
                Container(
                  color: Colors.blue.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Text('DEBUG: Loading...\n$debugInfo', style: const TextStyle(fontSize: 10)),
                ),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }
          
          if (state is EventDetailError) {
            debugInfo += 'Error: ${state.message}';
            return _buildFallbackView(context, error: state.message, debugInfo: debugInfo);
          }
          
          if (state is EventDetailLoaded) {
            final detail = state.eventDetail;
            debugInfo += 'Loaded! Title: ${detail.title}\n';
            debugInfo += 'Abstract length: ${detail.abstract.length}\n';
            debugInfo += 'Description length: ${detail.description.length}\n';
            debugInfo += 'Speakers: ${detail.speakers.length}\n';
            debugInfo += 'Links: ${detail.links.length}\n';
            debugInfo += 'Attachments: ${detail.attachments.length}';
            return _buildDetailedView(context, state, debugInfo);
          }
          
          debugInfo += 'State: Initial (not yet loaded)';
          return _buildFallbackView(context, debugInfo: debugInfo);
        },
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, EventDetailLoaded state, String debugInfo) {
    final detail = state.eventDetail;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debug info card
          Card(
            color: Colors.green.shade100,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DEBUG: Scraper Success!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(debugInfo, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(context),
          const SizedBox(height: 16),
          if (detail.abstract.isNotEmpty) ...[
            _buildSection(context, 'Abstract (Scraped)', detail.abstract),
            const SizedBox(height: 16),
          ],
          if (detail.description.isNotEmpty) ...[
            _buildSection(context, 'Description (Scraped)', detail.description),
            const SizedBox(height: 16),
          ],
          if (detail.speakers.isNotEmpty) ...[
            _buildSpeakers(context, detail.speakers),
            const SizedBox(height: 16),
          ],
          if (detail.links.isNotEmpty) ...[
            _buildLinks(context, detail.links),
            const SizedBox(height: 16),
          ],
          if (detail.attachments.isNotEmpty) ...[
            _buildAttachments(context, detail.attachments),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackView(BuildContext context, {String? error, String? debugInfo}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Debug info card
          if (debugInfo != null) ...[
            Card(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(debugInfo, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (error != null) ...[
            Card(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Could not load full details: $error',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildDescription(context),
          if (event.people.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBasicSpeakers(context),
          ],
          if (event.links.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBasicLinks(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${event.start.toLocal()} - ${event.durationText}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Text(
                  event.room,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (event.track.isNotEmpty) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(event.track),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          event.description ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (event.abstract != null && event.abstract!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Abstract',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            event.abstract!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildSpeakers(BuildContext context, List<dynamic> speakers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speakers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...speakers.map((speaker) => ListTile(
              leading: CircleAvatar(
                child: Text(speaker.name[0].toUpperCase()),
              ),
              title: Text(speaker.name),
              subtitle: Text(speaker.profileUrl),
              onTap: () {
                // TODO: Open speaker profile
              },
            )),
      ],
    );
  }

  Widget _buildBasicSpeakers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speakers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...event.people.map((person) => ListTile(
              leading: CircleAvatar(
                child: Text(person.name[0].toUpperCase()),
              ),
              title: Text(person.name),
            )),
      ],
    );
  }

  Widget _buildLinks(BuildContext context, List<dynamic> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...links.map((link) => ListTile(
              leading: const Icon(Icons.link),
              title: Text(link.title),
              subtitle: Text(link.url),
              onTap: () {
                // TODO: Open URL
              },
            )),
      ],
    );
  }

  Widget _buildBasicLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...event.links.map((link) => ListTile(
              leading: const Icon(Icons.link),
              title: Text(link.title),
              subtitle: Text(link.url),
              onTap: () {
                // TODO: Open URL
              },
            )),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context, List<dynamic> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...attachments.map((attachment) => ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(attachment.title),
              subtitle: Text(attachment.url),
              onTap: () {
                // TODO: Download/Open attachment
              },
            )),
      ],
    );
  }
}
