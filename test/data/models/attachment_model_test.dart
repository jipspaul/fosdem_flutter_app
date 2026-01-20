import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/models/attachment_model.dart';

void main() {
  group('AttachmentModel', () {
    test('detects attachment type from URL - PDF', () {
      final attachment = AttachmentModel.fromJson({
        'title': 'Slides',
        'url': 'https://example.com/presentation.pdf',
      });
      
      expect(attachment.type, AttachmentType.slides);
      expect(attachment.isSlides, true);
    });

    test('detects attachment type from URL - MP4', () {
      final attachment = AttachmentModel.fromJson({
        'title': 'Video',
        'url': 'https://example.com/video.mp4',
      });
      
      expect(attachment.type, AttachmentType.video);
      expect(attachment.isVideo, true);
    });

    test('AttachmentType displayName works correctly', () {
      expect(AttachmentType.slides.displayName, 'Slides');
      expect(AttachmentType.video.displayName, 'Video');
      expect(AttachmentType.audio.displayName, 'Audio');
    });

    test('fileExtension extracted correctly', () {
      final attachment = AttachmentModel(
        title: 'Test',
        url: 'https://example.com/file.pdf',
        type: AttachmentType.slides,
      );
      
      expect(attachment.fileExtension, 'pdf');
    });
  });
}
