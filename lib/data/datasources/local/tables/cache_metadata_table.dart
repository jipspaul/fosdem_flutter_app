import 'package:drift/drift.dart';

@DataClassName('CacheMetadata')
class CacheMetadataTable extends Table {
  @override
  String get tableName => 'cache_metadata';
  
  TextColumn get key => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  IntColumn get sizeBytes => integer()();
  IntColumn get accessCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {key};
}
