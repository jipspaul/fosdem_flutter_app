import 'package:equatable/equatable.dart';

enum AttachmentType {
  slides,
  video,
  audio,
  document,
  other;

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

class Attachment extends Equatable {
  final String title;
  final String url;
  final AttachmentType type;

  const Attachment({
    required this.title,
    required this.url,
    required this.type,
  });

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

  Attachment copyWith({
    String? title,
    String? url,
    AttachmentType? type,
  }) {
    return Attachment(
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [title, url, type];

  @override
  String toString() => 'Attachment(title: $title, type: ${type.name})';
}
