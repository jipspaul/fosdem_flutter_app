import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/filter_presets_table.dart';

part 'filter_presets_dao.g.dart';

@DriftAccessor(tables: [FilterPresets])
class FilterPresetsDao extends DatabaseAccessor<AppDatabase> with _$FilterPresetsDaoMixin {
  FilterPresetsDao(AppDatabase db) : super(db);

  // Get all presets
  Future<List<FilterPreset>> getAllPresets() => select(filterPresets).get();

  // Get default preset
  Future<FilterPreset?> getDefaultPreset() =>
      (select(filterPresets)..where((t) => t.isDefault.equals(true))).getSingleOrNull();

  // Save preset
  Future<int> savePreset(FilterPresetsCompanion preset) =>
      into(filterPresets).insert(preset, mode: InsertMode.insertOrReplace);

  // Update preset
  Future<bool> updatePreset(FilterPreset preset) =>
      update(filterPresets).replace(preset);

  // Delete preset
  Future<int> deletePreset(int id) =>
      (delete(filterPresets)..where((t) => t.id.equals(id))).go();

  // Set as default (clear other defaults first)
  Future<void> setAsDefault(int id) => transaction(() async {
        await (update(filterPresets)..where((t) => t.isDefault.equals(true)))
            .write(const FilterPresetsCompanion(isDefault: Value(false)));
        await (update(filterPresets)..where((t) => t.id.equals(id)))
            .write(const FilterPresetsCompanion(isDefault: Value(true)));
      });

  // Update last used
  Future<void> updateLastUsed(int id) =>
      (update(filterPresets)..where((t) => t.id.equals(id)))
          .write(FilterPresetsCompanion(lastUsedAt: Value(DateTime.now())));

  // Get preset by id
  Future<FilterPreset?> getPresetById(int id) =>
      (select(filterPresets)..where((t) => t.id.equals(id))).getSingleOrNull();
}
