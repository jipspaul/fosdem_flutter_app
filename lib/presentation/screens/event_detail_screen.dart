import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event.dart';
import '../../core/di/injection_container.dart' as di;
import '../bloc/event_detail/event_detail_bloc.dart';
import '../bloc/event_detail/event_detail_event.dart';
import '../bloc/event_detail/event_detail_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/journey/presentation/bloc/journey_bloc.dart';
import '../../features/journey/presentation/bloc/journey_event.dart';
import '../../features/journey/presentation/bloc/journey_state.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    print('DEBUG EventDetailScreen: Event "${event.title}"');
    print('DEBUG EventDetailScreen: Event URL = "${event.url}"');
    print('DEBUG EventDetailScreen: Event ID = ${event.id}');
    
    return BlocProvider(
      create: (context) => di.sl<EventDetailBloc>()..add(LoadEventDetail(event.url, event.id, event.title)),
      child: _EventDetailContent(event: event),
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  final Event event;

  const _EventDetailContent({required this.event});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: EventDetailScreen - Event: ${event.title}, URL: ${event.url}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          BlocBuilder<JourneyBloc, JourneyState>(
            builder: (context, journeyState) {
              if (journeyState is! JourneyLoaded) {
                return const SizedBox.shrink();
              }
              
              final isInJourney = journeyState.isInJourney(event.id);
              final isInWishlist = journeyState.isInWishlist(event.id);
              final journeyItem = journeyState.getItemByEventId(event.id);
              
              return IconButton(
                icon: Icon(
                  isInJourney ? Icons.event_available : Icons.event,
                  color: isInJourney ? Colors.green : (isInWishlist ? Colors.orange : null),
                ),
                onPressed: () {
                  if (isInJourney && journeyItem != null) {
                    // Remove from journey
                    context.read<JourneyBloc>().add(RemoveFromJourney(journeyItem.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from journey')),
                    );
                  } else {
                    // Add to journey
                    context.read<JourneyBloc>().add(AddToJourney(eventId: event.id));
                    
                    // We'll get updated state and check conflicts after bloc processes
                    Future.delayed(const Duration(milliseconds: 500), () {
                      final newState = context.read<JourneyBloc>().state;
                      if (newState is JourneyLoaded) {
                        final conflicts = newState.conflicts
                            .where((c) => c.affectedEvents.any((je) => je.eventId == event.id))
                            .toList();
                        
                        if (conflicts.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to journey with ${conflicts.length} conflict(s)'),
                              backgroundColor: Colors.orange,
                              action: SnackBarAction(
                                label: 'VIEW',
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/journey');
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to journey'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    });
                  }
                },
                tooltip: isInJourney ? 'Remove from journey' : 'Add to journey',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share event functionality
            },
          ),
        ],
      ),
      body: BlocBuilder<EventDetailBloc, EventDetailState>(
        builder: (context, state) {
          String debugInfo = 'State: ${state.runtimeType}\n';
          debugInfo += 'Event URL: ${event.url ?? "NULL"}\n';
          debugInfo += 'Event ID: ${event.id}\n';
          
          if (state is EventDetailLoading) {
            return Column(
              children: [
                Container(
                  color: Colors.blue.shade100,
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  child: Text('DEBUG: Scraping...\n$debugInfo', style: const TextStyle(fontSize: 10)),
                ),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }
          
          if (state is EventDetailError) {
            debugInfo += 'Error: ${state.message}';
            return _buildContent(context, debugInfo: debugInfo, error: state.message);
          }
          
          if (state is EventDetailLoaded) {
            final detail = state.eventDetail;
            debugInfo += 'SUCCESS!\n';
            debugInfo += 'Title: ${detail.title}\n';
            debugInfo += 'Abstract length: ${detail.abstract.length}\n';
            debugInfo += 'Description length: ${detail.description.length}\n';
            debugInfo += 'Speakers: ${detail.speakers.length}\n';
            debugInfo += 'Links: ${detail.links.length}\n';
            debugInfo += 'Attachments: ${detail.attachments.length}';
            return _buildContent(context, scrapedDetail: detail, debugInfo: debugInfo);
          }
          
          debugInfo += 'State: Initial';
          return _buildContent(context, debugInfo: debugInfo);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, {dynamic scrapedDetail, String? debugInfo, String? error}) {
    return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.subtitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
              const SizedBox(height: 24),

              // Scraped Content Section - Show prominently at the top if available
              if (scrapedDetail != null) ...[
                Card(
                  color: Colors.green.shade50,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_download, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Live Event Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        
                        // Abstract from web
                        if (scrapedDetail.abstract.isNotEmpty) ...[
                          Text(
                            'Abstract',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scrapedDetail.abstract,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Description from web
                        if (scrapedDetail.description.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            scrapedDetail.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Speakers from web
                        if (scrapedDetail.speakers.isNotEmpty) ...[
                          Text(
                            'Speakers',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...scrapedDetail.speakers.map((speaker) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.person, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  speaker.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                        
                        // Links from web
                        if (scrapedDetail.links.isNotEmpty) ...[
                          Text(
                            'Links',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...scrapedDetail.links.map((link) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: InkWell(
                              onTap: () => _launchUrl(link.url),
                              child: Row(
                                children: [
                                  const Icon(Icons.link, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      link.title,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                        
                        // Attachments from web
                        if (scrapedDetail.attachments.isNotEmpty) ...[
                          Text(
                            'Attachments',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...scrapedDetail.attachments.map((attachment) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: InkWell(
                              onTap: () => _launchUrl(attachment.url),
                              child: Row(
                                children: [
                                  const Icon(Icons.attachment, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      attachment.title,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.download, size: 16, color: Colors.blue),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Show error if scraping failed
              if (error != null) ...[
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not load live event information: $error',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Event Info Card - SECOND POSITION
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(context, Icons.calendar_today, 'Date', event.start.toString().split(' ')[0]),
                      _buildInfoRow(context, Icons.access_time, 'Time', '${event.start.toLocal().hour}:${event.start.toLocal().minute.toString().padLeft(2, '0')}'),
                      _buildInfoRow(context, Icons.timer, 'Duration', '${event.duration} min'),
                      _buildInfoRow(context, Icons.room, 'Room', event.room),
                      _buildInfoRow(context, Icons.category, 'Track', event.track),
                      if (event.url != null && event.url!.isNotEmpty)
                        _buildInfoRow(context, Icons.link, 'Event URL', event.url!, isUrl: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Data from xCal (from database) - COLLAPSED by default (THIRD POSITION)
              ExpansionTile(
                initiallyExpanded: false,
                backgroundColor: Colors.blue.shade50,
                collapsedBackgroundColor: Colors.blue.shade50,
                title: Row(
                  children: [
                    Icon(Icons.storage, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Event Data from xCal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow('Event ID', '${event.id}'),
                        _buildDataRow('Title', event.title),
                        if (event.subtitle != null) _buildDataRow('Subtitle', event.subtitle!),
                        _buildDataRow('Room', event.room),
                        _buildDataRow('Track', event.track),
                        _buildDataRow('Date', event.date.toString().split(' ')[0]),
                        _buildDataRow('Start Time', event.start.toString()),
                        _buildDataRow('Duration', '${event.duration} minutes'),
                        if (event.abstract != null) _buildDataRow('Has Abstract', event.abstract!.isNotEmpty ? 'Yes' : 'No'),
                        if (event.description != null) _buildDataRow('Has Description', event.description!.isNotEmpty ? 'Yes' : 'No'),
                        _buildDataRow('Speakers Count', '${event.people.length}'),
                        _buildDataRow('Links Count', '${event.links.length}'),
                        _buildDataRow('Attachments Count', '${event.attachments.length}'),
                        if (event.url != null && event.url!.isNotEmpty)
                          _buildDataRow('URL', event.url!, isUrl: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Speakers Section (from xCal if not scraped)
              if (scrapedDetail == null && event.people.isNotEmpty) ...[
                Text(
                  'Speakers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...event.people.map((speaker) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(speaker.name),
                      ),
                    )),
                const SizedBox(height: 24),
              ],

              // Abstract Section (from xCal if not scraped)
              if (scrapedDetail == null && event.abstract != null && event.abstract!.isNotEmpty) ...[
                Text(
                  'Abstract',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.abstract!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],

              // Description Section (from xCal if not scraped)
              if (scrapedDetail == null && event.description != null && event.description!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],

              // Links Section (from xCal if not scraped)
              if (scrapedDetail == null && event.links.isNotEmpty) ...[
                Text(
                  'Links',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...event.links.map((link) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.link),
                        title: Text(link.title),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchUrl(link.url),
                      ),
                    )),
                const SizedBox(height: 24),
              ],

              // Attachments Section (from xCal if not scraped)
              if (scrapedDetail == null && event.attachments.isNotEmpty) ...[
                Text(
                  'Attachments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...event.attachments.map((attachment) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.attachment),
                        title: Text(attachment.title),
                        trailing: const Icon(Icons.download),
                        onTap: () => _launchUrl(attachment.url),
                      ),
                    )),
              ],
            ],
          ),
        ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isUrl = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: isUrl 
              ? InkWell(
                  onTap: () => _launchUrl(value),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isUrl = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: isUrl
              ? InkWell(
                  onTap: () => _launchUrl(value),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 13),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
