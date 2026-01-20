import 'package:equatable/equatable.dart';

class BlueprintModel extends Equatable {
  final String title;
  final String imageName;
  final String? imageUrl;

  const BlueprintModel({
    required this.title,
    required this.imageName,
    this.imageUrl,
  });

  factory BlueprintModel.fromJson(Map<String, dynamic> json) {
    return BlueprintModel(
      title: json['title'] as String,
      imageName: json['image_name'] as String? ?? json['imageName'] as String,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageName': imageName,
      'imageUrl': imageUrl,
    };
  }

  bool get hasNetworkImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasAssetImage => imageName.isNotEmpty;

  String get imageAssetPath => 'assets/images/$imageName';

  BlueprintModel copyWith({
    String? title,
    String? imageName,
    String? imageUrl,
  }) {
    return BlueprintModel(
      title: title ?? this.title,
      imageName: imageName ?? this.imageName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [title, imageName, imageUrl];
}
