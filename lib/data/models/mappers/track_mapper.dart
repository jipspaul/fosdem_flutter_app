import 'package:flutter/material.dart';
import '../../datasources/local/database.dart';
import '../../../domain/entities/track.dart';
import 'package:drift/drift.dart' hide JsonKey;

extension TrackEntityMapper on TrackEntity {
  Track toEntity() {
    Color trackColor = Colors.blue;
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        final hex = colorHex!.replaceAll('#', '');
        trackColor = Color(int.parse(hex, radix: 16) + 0xFF000000);
      } catch (e) {
        // Use default color if parsing fails
      }
    }
    
    return Track(
      name: name,
      day: day,
      date: date,
      color: trackColor,
      description: description ?? '',
    );
  }
}

extension TrackModelMapper on Track {
  TracksCompanion toCompanion() {
    return TracksCompanion(
      name: Value(name),
      type: Value('track'),
      description: const Value(null),
    );
  }
}
