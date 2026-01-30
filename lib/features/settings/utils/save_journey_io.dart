import 'dart:io';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves YAML to a file and opens the share sheet (mobile/desktop).
/// Used only when dart.library.io is available (not on web).
Future<String> saveAndShareJourneyYaml(String yaml) async {
  Directory dir;
  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      if (!await downloads.exists()) {
        await downloads.create(recursive: true);
      }
      dir = downloads;
    } else {
      dir = await getTemporaryDirectory();
    }
  } on UnsupportedError {
    dir = await getTemporaryDirectory();
  }
  final file = File('${dir.path}/journey.yaml');
  await file.writeAsString(yaml, flush: true);
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'My FOSDEM Journey',
    text: 'My FOSDEM journey (YAML file)',
    sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
  );
  return '${dir.path}/journey.yaml';
}
