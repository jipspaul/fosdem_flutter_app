import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../repositories/event_repository.dart';
import '../repositories/track_repository.dart';
import 'xcal_parser_service.dart';
import 'xcal_monitor_service.dart';

class DataLoadingService {
  final EventRepository eventRepository;
  final TrackRepository trackRepository;
  final XCalParserService parserService;
  final Dio dio;
  final XCalMonitorService? monitorService;

  DataLoadingService({
    required this.eventRepository,
    required this.trackRepository,
    required this.parserService,
    required this.dio,
    this.monitorService,
  });

  /// Load initial data from bundled xcal file
  Future<void> loadBundledData() async {
    try {
      print('Loading bundled xcal data...');
      final xmlContent = await rootBundle.loadString('assets/xcal');
      await _processXCalData(xmlContent);
      print('Bundled data loaded successfully');
    } catch (e) {
      print('Error loading bundled data: $e');
      rethrow;
    }
  }

  /// Load data from a URL
  Future<void> loadFromUrl(String url) async {
    try {
      print('Loading xcal data from URL: $url');
      final response = await dio.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load data from URL: ${response.statusCode}');
      }
      
      await _processXCalData(response.data.toString());
      print('Data loaded successfully from URL');
    } catch (e) {
      print('Error loading data from URL: $e');
      rethrow;
    }
  }

  /// Process and save xcal data
  Future<void> _processXCalData(String xmlContent) async {
    print('🔄 Processing xcal data...');
    
    // Parse events
    final events = await parserService.parseXCalString(xmlContent);
    print('✅ Parsed ${events.length} events');

    if (events.isEmpty) {
      print('⚠️  WARNING: No events were parsed from xcal!');
      return;
    }

    // Extract tracks
    final tracks = parserService.extractTracks(events);
    print('✅ Extracted ${tracks.length} tracks');

    // DON'T clear existing data - use upsert to preserve favorites
    // Only clear tracks since they don't have favorites
    await trackRepository.deleteAll();
    print('🗑️  Cleared existing tracks');

    // Save tracks first
    for (final track in tracks) {
      await trackRepository.create(track);
    }
    print('💾 Saved ${tracks.length} tracks to database');

    // Save events using upsert to preserve favorites
    int savedCount = 0;
    for (final event in events) {
      await eventRepository.upsert(event);
      savedCount++;
      if (savedCount % 100 == 0) {
        print('  Progress: $savedCount/${events.length} events saved...');
      }
    }
    print('💾 Saved ${events.length} events to database (favorites preserved)');

    print('✅ Data saved to database successfully!');
  }

  /// Check if data exists in database
  Future<bool> hasData() async {
    final events = await eventRepository.getAll();
    return events.isNotEmpty;
  }

  /// Check for changes and update if content has changed
  /// Returns true if update occurred, false if no changes detected
  /// Throws exception on error
  Future<bool> checkAndUpdateIfChanged(String url) async {
    if (monitorService == null) {
      throw Exception('XCalMonitorService not available');
    }

    try {
      print('🔍 Checking for changes in xCal URL: $url');
      
      // Check if content has changed
      final hasChanged = await monitorService!.checkForChanges(url);
      
      if (!hasChanged) {
        print('✅ No changes detected - database is up to date');
        return false;
      }

      print('🔄 Changes detected - updating database...');
      
      // Load and update data from URL
      await loadFromUrl(url);
      
      print('✅ Database updated successfully');
      return true;
    } catch (e) {
      print('❌ Error checking/updating: $e');
      rethrow;
    }
  }
}
