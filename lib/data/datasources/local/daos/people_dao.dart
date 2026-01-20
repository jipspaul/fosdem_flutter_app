import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/people_table.dart';

part 'people_dao.g.dart';

@DriftAccessor(tables: [People])
class PeopleDao extends DatabaseAccessor<AppDatabase> with _$PeopleDaoMixin {
  PeopleDao(AppDatabase db) : super(db);

  Future<List<PersonEntity>> getAllPeople() => select(people).get();
  
  Future<PersonEntity?> getPersonById(int id) =>
      (select(people)..where((p) => p.id.equals(id))).getSingleOrNull();
  
  Future<List<PersonEntity>> searchPeople(String query) =>
      (select(people)..where((p) => p.name.like('%$query%'))).get();
  
  Future<int> insertPerson(PeopleCompanion person) =>
      into(people).insert(person);
  
  Future<void> insertPeople(List<PeopleCompanion> peopleList) async {
    await batch((batch) {
      batch.insertAll(people, peopleList, mode: InsertMode.insertOrIgnore);
    });
  }
  
  Future<bool> updatePerson(PersonEntity person) => update(people).replace(person);
  
  Future<int> deletePerson(int id) =>
      (delete(people)..where((p) => p.id.equals(id))).go();
  
  Stream<List<PersonEntity>> watchAllPeople() => select(people).watch();
}
