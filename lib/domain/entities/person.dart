import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final int id;
  final String name;
  final String? bio;
  final String? avatar;

  const Person({
    required this.id,
    required this.name,
    this.bio,
    this.avatar,
  });

  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  bool get hasBio => bio != null && bio!.isNotEmpty;

  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Person copyWith({
    int? id,
    String? name,
    String? bio,
    String? avatar,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  List<Object?> get props => [id, name, bio, avatar];

  @override
  String toString() => 'Person(id: $id, name: $name)';
}
