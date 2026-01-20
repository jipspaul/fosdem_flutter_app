import 'package:equatable/equatable.dart';

class Link extends Equatable {
  final String title;
  final String url;
  final bool isVideo;
  final bool isMP4Video;

  const Link({
    required this.title,
    required this.url,
    this.isVideo = false,
    this.isMP4Video = false,
  });

  bool get isYouTube => url.contains('youtube.com') || url.contains('youtu.be');
  bool get isVimeo => url.contains('vimeo.com');
  bool get isFosdemVideo => url.contains('video.fosdem.org');

  String? get youtubeVideoId {
    if (!isYouTube) return null;
    
    final uri = Uri.parse(url);
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.firstOrNull;
    }
    return uri.queryParameters['v'];
  }

  Link copyWith({
    String? title,
    String? url,
    bool? isVideo,
    bool? isMP4Video,
  }) {
    return Link(
      title: title ?? this.title,
      url: url ?? this.url,
      isVideo: isVideo ?? this.isVideo,
      isMP4Video: isMP4Video ?? this.isMP4Video,
    );
  }

  @override
  List<Object?> get props => [title, url, isVideo, isMP4Video];

  @override
  String toString() => 'Link(title: $title, isVideo: $isVideo)';
}
