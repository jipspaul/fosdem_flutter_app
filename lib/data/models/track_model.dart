import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TrackModel extends Equatable {
  final String name;
  final int? day;
  final DateTime? date;
  final String? colorHex;

  const TrackModel({
    required this.name,
    this.day,
    this.date,
    this.colorHex,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date'] as String);
      } catch (e) {
        date = null;
      }
    }

    return TrackModel(
      name: json['name'] as String,
      day: json['day'] as int?,
      date: date,
      colorHex: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'day': day,
      'date': date?.toIso8601String(),
      'color': colorHex,
    };
  }

  Color get color {
    if (colorHex == null) return Colors.blue;
    
    try {
      // Remove # if present
      String hex = colorHex!.replaceAll('#', '');
      
      // Add alpha if not present
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String get displayDay {
    if (day != null) return 'Day $day';
    if (date != null) {
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date!.weekday - 1];
      return '$weekday ${date!.day}/${date!.month}';
    }
    return 'Unknown Day';
  }

  bool isOnDay(DateTime checkDate) {
    if (date == null) return false;
    return date!.year == checkDate.year &&
        date!.month == checkDate.month &&
        date!.day == checkDate.day;
  }

  TrackModel copyWith({
    String? name,
    int? day,
    DateTime? date,
    String? colorHex,
  }) {
    return TrackModel(
      name: name ?? this.name,
      day: day ?? this.day,
      date: date ?? this.date,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [name, day, date, colorHex];
}
