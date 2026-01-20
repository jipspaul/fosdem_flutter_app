import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final SharedPreferences prefs;
  static const String _favoritesKey = 'favorite_events';

  FavoritesRepositoryImpl({required this.prefs});

  Future<Set<String>> _getFavoriteSet() async {
    final jsonStr = prefs.getString(_favoritesKey);
    if (jsonStr == null) return {};
    
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.cast<String>().toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveFavoriteSet(Set<String> favorites) async {
    final jsonStr = json.encode(favorites.toList());
    await prefs.setString(_favoritesKey, jsonStr);
  }

  @override
  Future<Either<Failure, void>> addFavorite(String eventId) async {
    try {
      final favorites = await _getFavoriteSet();
      favorites.add(eventId);
      await _saveFavoriteSet(favorites);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFavorite(String eventId) async {
    try {
      final favorites = await _getFavoriteSet();
      favorites.remove(eventId);
      await _saveFavoriteSet(favorites);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite(String eventId) async {
    try {
      final favorites = await _getFavoriteSet();
      return Right(favorites.contains(eventId));
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFavoriteIds() async {
    try {
      final favorites = await _getFavoriteSet();
      return Right(favorites.toList());
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleFavorite(String eventId) async {
    try {
      final favorites = await _getFavoriteSet();
      final isFav = favorites.contains(eventId);
      
      if (isFav) {
        favorites.remove(eventId);
      } else {
        favorites.add(eventId);
      }
      
      await _saveFavoriteSet(favorites);
      return Right(!isFav);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Stream<List<String>> watchFavorites() async* {
    // Initial emit
    final favorites = await _getFavoriteSet();
    yield favorites.toList();
    
    // Note: SharedPreferences doesn't have built-in watching
    // In a real app, you'd use a StreamController and notify on changes
  }

  @override
  Future<Either<Failure, void>> syncFavorites() async {
    // Future feature: sync with cloud storage
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearAllFavorites() async {
    try {
      await prefs.remove(_favoritesKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportFavorites() async {
    try {
      final favorites = await _getFavoriteSet();
      final jsonStr = json.encode({
        'favorites': favorites.toList(),
        'exportDate': DateTime.now().toIso8601String(),
      });
      return Right(jsonStr);
    } catch (e) {
      return Left(CacheFailure( e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> importFavorites(String jsonStr) async {
    try {
      final data = json.decode(jsonStr);
      final List<dynamic> favoritesList = data['favorites'] ?? [];
      final favorites = favoritesList.cast<String>().toSet();
      await _saveFavoriteSet(favorites);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure( 'Invalid import data: ${e.toString()}'));
    }
  }
}
