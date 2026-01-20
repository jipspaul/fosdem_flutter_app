import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_filter.dart';

class FilterPersistenceService {
  final SharedPreferences prefs;
  static const String _filtersKey = 'saved_filters';
  
  FilterPersistenceService(this.prefs);
  
  Future<void> saveFilters(List<EventFilter> filters) async {
    final json = filters.map((f) => f.toJson()).toList();
    await prefs.setString(_filtersKey, jsonEncode(json));
  }
  
  Future<List<EventFilter>> loadFilters() async {
    final jsonString = prefs.getString(_filtersKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> json = jsonDecode(jsonString);
      return json.map((j) => EventFilter.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading filters: $e');
      return [];
    }
  }
  
  Future<void> clearFilters() async {
    await prefs.remove(_filtersKey);
  }
}
