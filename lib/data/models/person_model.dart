import 'package:equatable/equatable.dart';

class PersonModel extends Equatable {
  final int id;
  final String name;
  final String? bio;
  final String? avatar;

  const PersonModel({
    required this.id,
    required this.name,
    this.bio,
    this.avatar,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as int,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatar': avatar,
    };
  }

  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  bool get hasBio => bio != null && bio!.isNotEmpty;

  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  PersonModel copyWith({
    int? id,
    String? name,
    String? bio,
    String? avatar,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  List<Object?> get props => [id, name, bio, avatar];
}
