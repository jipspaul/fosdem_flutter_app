import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Track extends Equatable {
  final String name;
  final int? day;
  final DateTime? date;
  final Color color;
  final String description;

  const Track({
    required this.name,
    this.day,
    this.date,
    this.color = Colors.blue,
    this.description = '',
  });

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

  Track copyWith({
    String? name,
    int? day,
    DateTime? date,
    Color? color,
    String? description,
  }) {
    return Track(
      name: name ?? this.name,
      day: day ?? this.day,
      date: date ?? this.date,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [name, day, date, color, description];

  @override
  String toString() => 'Track(name: $name, day: $day)';
}
