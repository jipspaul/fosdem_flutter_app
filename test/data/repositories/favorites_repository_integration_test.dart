import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fosdem_flutter/data/repositories/favorites_repository_impl.dart';

void main() {
  group('FavoritesRepository Integration Tests', () {
    late FavoritesRepositoryImpl repository;
    late SharedPreferences prefs;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = FavoritesRepositoryImpl(prefs: prefs);
    });

    tearDown(() async {
      await prefs.clear();
    });

    test('should add and retrieve favorite', () async {
      // Act
      final addResult = await repository.addFavorite('event1');
      final isFavResult = await repository.isFavorite('event1');

      // Assert
      expect(addResult.isRight(), true);
      expect(isFavResult.isRight(), true);
      isFavResult.fold(
        (_) => fail('Should return Right'),
        (isFav) => expect(isFav, true),
      );
    });

    test('should remove favorite', () async {
      // Arrange
      await repository.addFavorite('event1');

      // Act
      final removeResult = await repository.removeFavorite('event1');
      final isFavResult = await repository.isFavorite('event1');

      // Assert
      expect(removeResult.isRight(), true);
      isFavResult.fold(
        (_) => fail('Should return Right'),
        (isFav) => expect(isFav, false),
      );
    });

    test('should toggle favorite status', () async {
      // Act & Assert - First toggle (add)
      final firstToggle = await repository.toggleFavorite('event1');
      firstToggle.fold(
        (_) => fail('Should return Right'),
        (isFav) => expect(isFav, true),
      );

      // Act & Assert - Second toggle (remove)
      final secondToggle = await repository.toggleFavorite('event1');
      secondToggle.fold(
        (_) => fail('Should return Right'),
        (isFav) => expect(isFav, false),
      );
    });

    test('should get all favorite IDs', () async {
      // Arrange
      await repository.addFavorite('event1');
      await repository.addFavorite('event2');
      await repository.addFavorite('event3');

      // Act
      final result = await repository.getFavoriteIds();

      // Assert
      result.fold(
        (_) => fail('Should return Right'),
        (ids) {
          expect(ids.length, 3);
          expect(ids, contains('event1'));
          expect(ids, contains('event2'));
          expect(ids, contains('event3'));
        },
      );
    });

    test('should clear all favorites', () async {
      // Arrange
      await repository.addFavorite('event1');
      await repository.addFavorite('event2');

      // Act
      await repository.clearAllFavorites();
      final result = await repository.getFavoriteIds();

      // Assert
      result.fold(
        (_) => fail('Should return Right'),
        (ids) => expect(ids.isEmpty, true),
      );
    });

    test('should export favorites as JSON', () async {
      // Arrange
      await repository.addFavorite('event1');
      await repository.addFavorite('event2');

      // Act
      final result = await repository.exportFavorites();

      // Assert
      result.fold(
        (_) => fail('Should return Right'),
        (json) {
          expect(json, contains('event1'));
          expect(json, contains('event2'));
          expect(json, contains('exportDate'));
        },
      );
    });

    test('should import favorites from JSON', () async {
      // Arrange
      const jsonData = '{"favorites":["event1","event2"],"exportDate":"2025-01-01"}';

      // Act
      final importResult = await repository.importFavorites(jsonData);
      final idsResult = await repository.getFavoriteIds();

      // Assert
      expect(importResult.isRight(), true);
      idsResult.fold(
        (_) => fail('Should return Right'),
        (ids) {
          expect(ids.length, 2);
          expect(ids, contains('event1'));
          expect(ids, contains('event2'));
        },
      );
    });

    test('should handle invalid JSON on import', () async {
      // Act
      final result = await repository.importFavorites('invalid json');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, contains('Invalid import data')),
        (_) => fail('Should return Left'),
      );
    });

    test('should persist favorites across instances', () async {
      // Arrange
      await repository.addFavorite('event1');

      // Act - Create new repository instance with same prefs
      final newRepository = FavoritesRepositoryImpl(prefs: prefs);
      final result = await newRepository.isFavorite('event1');

      // Assert
      result.fold(
        (_) => fail('Should return Right'),
        (isFav) => expect(isFav, true),
      );
    });

    test('should handle multiple rapid toggles', () async {
      // Act
      await repository.toggleFavorite('event1');
      await repository.toggleFavorite('event1');
      await repository.toggleFavorite('event1');
      final result = await repository.isFavorite('event1');

      // Assert
      result.fold(
        (_) => fail('Should return Right'),
        (isFav) => expect(isFav, true), // Odd number of toggles
      );
    });
  });
}
