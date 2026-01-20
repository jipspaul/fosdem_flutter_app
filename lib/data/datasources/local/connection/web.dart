import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor constructDb() {
  return WebDatabase('fosdem_db', logStatements: true);
}
