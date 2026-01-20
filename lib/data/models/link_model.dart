import 'package:equatable/equatable.dart';

class LinkModel extends Equatable {
  final String title;
  final String url;
  final bool isVideo;
  final bool isMP4Video;

  const LinkModel({
    required this.title,
    required this.url,
    this.isVideo = false,
    this.isMP4Video = false,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final title = json['title'] as String? ?? json['name'] as String? ?? 'Link';
    
    return LinkModel(
      title: title,
      url: url,
      isVideo: _isVideoUrl(url),
      isMP4Video: _isMP4VideoUrl(url),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'isVideo': isVideo,
      'isMP4Video': isMP4Video,
    };
  }

  static bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv'];
    final videoHosts = ['youtube.com', 'youtu.be', 'vimeo.com', 'video.fosdem.org'];
    
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext)) ||
        videoHosts.any((host) => lowerUrl.contains(host));
  }

  static bool _isMP4VideoUrl(String url) {
    return url.toLowerCase().endsWith('.mp4');
  }

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

  LinkModel copyWith({
    String? title,
    String? url,
    bool? isVideo,
    bool? isMP4Video,
  }) {
    return LinkModel(
      title: title ?? this.title,
      url: url ?? this.url,
      isVideo: isVideo ?? this.isVideo,
      isMP4Video: isMP4Video ?? this.isMP4Video,
    );
  }

  @override
  List<Object?> get props => [title, url, isVideo, isMP4Video];
}
