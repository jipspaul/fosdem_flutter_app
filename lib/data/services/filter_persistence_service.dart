import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../datasources/local/database.dart';
import '../datasources/local/daos/filter_presets_dao.dart';
import '../../domain/models/filter_models.dart';

class FilterPersistenceService {
  final FilterPresetsDao _presetsDao;

  FilterPersistenceService(AppDatabase database)
      : _presetsDao = database.filterPresetsDao;

  // Save current filter as preset
  Future<int> saveFilterPreset(String name, EventFilter filter, {bool isDefault = false}) async {
    final filterJson = jsonEncode(filter.toJson());
    final preset = FilterPresetsCompanion.insert(
      name: name,
      filterJson: filterJson,
      isDefault: Value(isDefault),
    );
    return await _presetsDao.savePreset(preset);
  }

  // Load all presets
  Future<List<FilterPresetModel>> loadAllPresets() async {
    final presets = await _presetsDao.getAllPresets();
    return presets.map((p) => FilterPresetModel(
      id: p.id,
      name: p.name,
      filter: EventFilter.fromJson(jsonDecode(p.filterJson)),
      isDefault: p.isDefault,
      createdAt: p.createdAt,
      lastUsedAt: p.lastUsedAt,
    )).toList();
  }

  // Load default preset
  Future<EventFilter?> loadDefaultFilter() async {
    final preset = await _presetsDao.getDefaultPreset();
    if (preset == null) return null;
    return EventFilter.fromJson(jsonDecode(preset.filterJson));
  }

  // Update preset
  Future<void> updatePreset(int id, String name, EventFilter filter) async {
    final preset = await _presetsDao.getPresetById(id);
    if (preset == null) return;

    final updated = preset.copyWith(
      name: name,
      filterJson: jsonEncode(filter.toJson()),
    );
    await _presetsDao.updatePreset(updated);
  }

  // Delete preset
  Future<void> deletePreset(int id) async {
    await _presetsDao.deletePreset(id);
  }

  // Set preset as default
  Future<void> setAsDefault(int id) async {
    await _presetsDao.setAsDefault(id);
  }

  // Update last used timestamp
  Future<void> markAsUsed(int id) async {
    await _presetsDao.updateLastUsed(id);
  }

  // Quick presets - commonly used filters
  Future<void> createQuickPresets() async {
    final existingPresets = await _presetsDao.getAllPresets();
    if (existingPresets.isNotEmpty) return; // Already have presets

    // "Today's Events"
    await saveFilterPreset(
      'Today\'s Events',
      EventFilter(
        dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 1)),
        ),
      ),
    );

    // "My Favorite Tracks"
    await saveFilterPreset(
      'Keynotes Only',
      EventFilter(
        tracks: {'keynotes'},
      ),
    );

    // "Quick Sessions" - events under 30 minutes
    await saveFilterPreset(
      'Quick Sessions',
      EventFilter(
        durationRange: const RangeValues(0, 30),
      ),
    );
  }
}

class FilterPresetModel {
  final int id;
  final String name;
  final EventFilter filter;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  FilterPresetModel({
    required this.id,
    required this.name,
    required this.filter,
    required this.isDefault,
    required this.createdAt,
    this.lastUsedAt,
  });
}
