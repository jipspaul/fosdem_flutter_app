import 'dart:convert';
import 'dart:html' as html;

/// Triggers a browser download of the journey YAML file (web only).
/// Used only when dart.library.html is available.
Future<String> saveAndShareJourneyYaml(String yaml) async {
  final bytes = utf8.encode(yaml);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = 'journey.yaml';
  final body = html.document.body;
  if (body != null) {
    body.children.add(anchor);
    anchor.click();
    body.children.remove(anchor);
  }
  html.Url.revokeObjectUrl(url);
  return 'journey.yaml';
}
