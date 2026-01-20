import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/repositories/event_repository.dart';
import '../../../domain/entities/event.dart';
import '../../../presentation/bloc/event_detail/event_detail_bloc.dart';
import '../../../features/event/presentation/pages/event_detail_page.dart' as feature;

class EventDetailPage extends StatelessWidget {
  final String eventId;
  
  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: EventDetailPage wrapper - eventId: $eventId');
    
    return FutureBuilder<Event?>(
      future: di.sl<EventRepository>().getEventById(int.parse(eventId)),
      builder: (context, snapshot) {
        print('DEBUG: FutureBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          print('DEBUG: Error loading event: ${snapshot.error}');
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('Could not load event: ${snapshot.error ?? 'Event not found'}'),
            ),
          );
        }
        
        final event = snapshot.data!;
        print('DEBUG: Event loaded: ${event.title}, URL: ${event.url}');
        
        return BlocProvider(
          create: (context) {
            print('DEBUG: Creating EventDetailBloc');
            return di.sl<EventDetailBloc>();
          },
          child: feature.EventDetailPage(event: event),
        );
      },
    );
  }
}

