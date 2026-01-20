import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/models/event_model.dart';
import 'package:fosdem_flutter/data/models/person_model.dart';
import 'package:fosdem_flutter/data/mappers/model_mappers.dart';

void main() {
  group('Model Mappers', () {
    test('PersonModel to Entity conversion works', () {
      final model = PersonModel(
        id: 1,
        name: 'John Doe',
        bio: 'Developer',
      );
      
      final entity = model.toEntity();
      
      expect(entity.id, model.id);
      expect(entity.name, model.name);
      expect(entity.bio, model.bio);
    });

    test('Person Entity to Model conversion works', () {
      final entity = const PersonModel(
        id: 1,
        name: 'John Doe',
        bio: 'Developer',
      ).toEntity();
      
      final model = entity.toModel();
      
      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.bio, entity.bio);
    });

    test('EventModel to Entity conversion preserves all fields', () {
      final model = EventModel(
        id: 1,
        title: 'Test Event',
        room: 'H.1302',
        track: 'Testing',
        date: DateTime(2025, 2, 1),
        start: DateTime(2025, 2, 1, 10, 0),
        duration: 45,
        people: [
          PersonModel(id: 1, name: 'Speaker'),
        ],
      );
      
      final entity = model.toEntity();
      
      expect(entity.id, model.id);
      expect(entity.title, model.title);
      expect(entity.people.length, 1);
      expect(entity.people.first.name, 'Speaker');
    });

    test('List conversion works for events', () {
      final models = [
        EventModel(
          id: 1,
          title: 'Event 1',
          room: 'H.1302',
          track: 'Testing',
          date: DateTime(2025, 2, 1),
          start: DateTime(2025, 2, 1, 10, 0),
          duration: 45,
        ),
        EventModel(
          id: 2,
          title: 'Event 2',
          room: 'H.1303',
          track: 'Testing',
          date: DateTime(2025, 2, 1),
          start: DateTime(2025, 2, 1, 11, 0),
          duration: 45,
        ),
      ];
      
      final entities = models.toEntities();
      
      expect(entities.length, 2);
      expect(entities[0].id, 1);
      expect(entities[1].id, 2);
    });
  });
}
