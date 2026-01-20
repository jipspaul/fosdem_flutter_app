import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/building.dart';

class BuildingsService {
  final List<String> _buildingFiles = ['aw', 'f', 'h', 'j', 'k', 'u', 's'];

  Future<List<Building>> loadBuildings() async {
    final buildings = <Building>[];
    
    for (final file in _buildingFiles) {
      try {
        final jsonString = await rootBundle.loadString('assets/Buildings/$file.json');
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final building = Building.fromJson(json);
        buildings.add(building);
      } catch (e) {
        print('Error loading building $file: $e');
      }
    }
    
    return buildings;
  }
}
