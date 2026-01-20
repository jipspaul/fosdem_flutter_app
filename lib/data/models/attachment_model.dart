import 'package:equatable/equatable.dart';

enum AttachmentType {
  slides,
  video,
  audio,
  document,
  other;

  static AttachmentType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'slides':
      case 'presentation':
      case 'pdf':
        return AttachmentType.slides;
      case 'video':
      case 'mp4':
      case 'webm':
        return AttachmentType.video;
      case 'audio':
      case 'mp3':
      case 'ogg':
        return AttachmentType.audio;
      case 'document':
      case 'doc':
      case 'txt':
        return AttachmentType.document;
      default:
        return AttachmentType.other;
    }
  }

  String get displayName {
    switch (this) {
      case AttachmentType.slides:
        return 'Slides';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.audio:
        return 'Audio';
      case AttachmentType.document:
        return 'Document';
      case AttachmentType.other:
        return 'Attachment';
    }
  }
}

class AttachmentModel extends Equatable {
  final String title;
  final String url;
  final AttachmentType type;

  const AttachmentModel({
    required this.title,
    required this.url,
    required this.type,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final title = json['title'] as String? ?? json['name'] as String? ?? 'Attachment';
    final typeString = json['type'] as String? ?? _detectTypeFromUrl(url);
    
    return AttachmentModel(
      title: title,
      url: url,
      type: AttachmentType.fromString(typeString),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'type': type.name,
    };
  }

  static String _detectTypeFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.endsWith('.pdf') || lowerUrl.contains('slides')) {
      return 'slides';
    } else if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.webm')) {
      return 'video';
    } else if (lowerUrl.endsWith('.mp3') || lowerUrl.endsWith('.ogg')) {
      return 'audio';
    } else if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.txt')) {
      return 'document';
    }
    
    return 'other';
  }

  bool get isSlides => type == AttachmentType.slides;

  bool get isVideo => type == AttachmentType.video;

  bool get isAudio => type == AttachmentType.audio;

  bool get isDocument => type == AttachmentType.document;

  String get fileExtension {
    final uri = Uri.parse(url);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot + 1).toLowerCase();
  }

  AttachmentModel copyWith({
    String? title,
    String? url,
    AttachmentType? type,
  }) {
    return AttachmentModel(
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [title, url, type];
}
