import 'dart:io';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves YAML to a temporary file and opens the share sheet (mobile/desktop).
/// Does not use Downloads folder; user can save to Files/Downloads via the share sheet.
Future<String> saveAndShareJourneyYaml(String yaml) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/journey.yaml');
  await file.writeAsString(yaml, flush: true);
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'My FOSDEM Journey',
    text: 'My FOSDEM journey (YAML file)',
    sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1),
  );
  return 'journey.yaml';
}
