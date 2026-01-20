import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fosdem_flutter/data/datasources/local/database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.test(NativeDatabase.memory());
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown() async {
    await database.close();
  }

  group('PeopleDao -', () {
    test('insertPerson and getPersonById works', () async {
      final person = const PeopleCompanion(
        name: Value('John Doe'),
        bio: Value('A software developer'),
      );

      final id = await database.peopleDao.insertPerson(person);
      final retrieved = await database.peopleDao.getPersonById(id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'John Doe');
      expect(retrieved.bio, 'A software developer');
    });

    test('searchPeople finds by name', () async {
      final people = [
        const PeopleCompanion(name: Value('John Doe')),
        const PeopleCompanion(name: Value('Jane Smith')),
        const PeopleCompanion(name: Value('John Smith')),
      ];

      await database.peopleDao.insertPeople(people);
      final results = await database.peopleDao.searchPeople('John');

      expect(results.length, 2);
      expect(results.every((p) => p.name.contains('John')), true);
    });

    test('getAllPeople returns all people', () async {
      final people = [
        const PeopleCompanion(name: Value('Person 1')),
        const PeopleCompanion(name: Value('Person 2')),
      ];

      await database.peopleDao.insertPeople(people);
      final retrieved = await database.peopleDao.getAllPeople();

      expect(retrieved.length, 2);
    });

    test('deletePerson removes person', () async {
      final person = const PeopleCompanion(name: Value('Test Person'));
      final id = await database.peopleDao.insertPerson(person);

      await database.peopleDao.deletePerson(id);
      expect(await database.peopleDao.getPersonById(id), isNull);
    });
  });
}
