import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/repositories/event_repository.dart';
import '../../bloc/favorites/favorites_bloc.dart';
import '../../bloc/favorites/favorites_event.dart';

class FavoritesDebugPage extends StatefulWidget {
  const FavoritesDebugPage({super.key});

  @override
  State<FavoritesDebugPage> createState() => _FavoritesDebugPageState();
}

class _FavoritesDebugPageState extends State<FavoritesDebugPage> {
  final _logs = <String>[];
  late final EventRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = di.sl<EventRepository>();
    _runDiagnostics();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)}: $message');
    });
    print('DEBUG: $message');
  }

  Future<void> _runDiagnostics() async {
    _addLog('Starting favorites diagnostics...');
    
    try {
      // Step 1: Check total events
      final allEvents = await _repository.getEvents();
      _addLog('Total events in database: ${allEvents.length}');
      
      if (allEvents.isEmpty) {
        _addLog('⚠️ No events found! Database might be empty.');
        return;
      }
      
      // Step 2: Check favorites
      final favorites = await _repository.getFavoriteEvents();
      _addLog('Current favorites: ${favorites.length}');
      
      if (favorites.isNotEmpty) {
        for (final fav in favorites) {
          _addLog('  - ${fav.title} (ID: ${fav.id})');
        }
      }
      
      // Step 3: Get first event and test toggling
      final firstEvent = allEvents.first;
      _addLog('Testing with event: "${firstEvent.title}" (ID: ${firstEvent.id})');
      
      // Check current state
      final dbEvent = await _repository.database.eventsDao.getEventById(firstEvent.id.toString());
      _addLog('Event isFavorite in DB: ${dbEvent?.isFavorite}');
      
      // Step 4: Try adding to favorites
      _addLog('Adding to favorites...');
      await _repository.addFavorite(firstEvent.id.toString());
      
      // Check if it worked
      final afterAdd = await _repository.database.eventsDao.getEventById(firstEvent.id.toString());
      _addLog('After add - isFavorite: ${afterAdd?.isFavorite}');
      
      // Step 5: Query favorites again
      final favoritesAfter = await _repository.getFavoriteEvents();
      _addLog('Favorites after add: ${favoritesAfter.length}');
      
      if (favoritesAfter.isEmpty) {
        _addLog('⚠️ Event was marked as favorite but getFavoriteEvents() returns empty!');
        
        // Debug: Check raw database query
        final rawFavorites = await _repository.database.eventsDao.getFavoriteEvents();
        _addLog('Raw DAO query favorites: ${rawFavorites.length}');
        
        if (rawFavorites.isNotEmpty) {
          _addLog('✓ DAO returns favorites, issue is in repository mapping');
        }
      } else {
        _addLog('✓ Successfully added to favorites!');
      }
      
      // Step 6: Try with FavoritesBloc
      _addLog('Testing FavoritesBloc...');
      context.read<FavoritesBloc>().add(const LoadFavorites());
      _addLog('LoadFavorites event dispatched');
      
    } catch (e, stackTrace) {
      _addLog('❌ Error: $e');
      _addLog('Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
              _runDiagnostics();
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              log,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: log.contains('❌') ? Colors.red :
                       log.contains('⚠️') ? Colors.orange :
                       log.contains('✓') ? Colors.green :
                       null,
              ),
            ),
          );
        },
      ),
    );
  }
}
