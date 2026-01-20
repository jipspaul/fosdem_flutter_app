import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/models/link_model.dart';

void main() {
  group('LinkModel', () {
    test('detects YouTube URLs correctly', () {
      final youtubeLink = LinkModel.fromJson({
        'title': 'YouTube',
        'url': 'https://youtube.com/watch?v=abc123',
      });
      
      expect(youtubeLink.isYouTube, true);
      expect(youtubeLink.isVideo, true);
    });

    test('extracts YouTube video ID correctly', () {
      final youtubeLink = LinkModel(
        title: 'YouTube',
        url: 'https://youtube.com/watch?v=abc123',
        isVideo: true,
      );
      
      expect(youtubeLink.youtubeVideoId, 'abc123');
    });

    test('detects MP4 videos correctly', () {
      final mp4Link = LinkModel.fromJson({
        'title': 'MP4 Video',
        'url': 'https://example.com/video.mp4',
      });
      
      expect(mp4Link.isMP4Video, true);
      expect(mp4Link.isVideo, true);
    });

    test('non-video URLs are not detected as video', () {
      final regularLink = LinkModel.fromJson({
        'title': 'Website',
        'url': 'https://example.com',
      });
      
      expect(regularLink.isVideo, false);
    });
  });
}
