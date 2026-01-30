import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';

import '../../domain/models/journey_export_model.dart';

/// Fetches and parses journey YAML from a URL.
/// Returns [JourneyExportData] or throws on invalid URL/format.
class JourneyImportService {
  final http.Client _client = http.Client();

  /// Fetches YAML from [url], parses it, and returns [JourneyExportData].
  /// Throws [JourneyImportException] on network or parse errors.
  Future<JourneyExportData> importJourneyFromUrl(String url) async {
    print('[Journey] ImportService: fetch url=$url');
    if (url.trim().isEmpty) {
      throw JourneyImportException('URL is empty');
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      print('[Journey] ImportService: invalid URI');
      throw JourneyImportException('Invalid URL');
    }

    final response = await _client.get(uri).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw JourneyImportException('Request timed out'),
    );

    print('[Journey] ImportService: response status=${response.statusCode} bodyLength=${response.body.length}');

    if (response.statusCode != 200) {
      throw JourneyImportException(
        'Failed to load: ${response.statusCode} ${response.reasonPhrase ?? ""}',
      );
    }

    final body = response.body;
    if (body.isEmpty) {
      throw JourneyImportException('Empty response');
    }

    try {
      final parsed = loadYaml(body);
      if (parsed == null) {
        print('[Journey] ImportService: loadYaml returned null');
        throw JourneyImportException('Invalid YAML');
      }
      final converted = _convert(parsed);
      final map = converted is Map ? Map<dynamic, dynamic>.from(converted) : null;
      if (map == null || map.isEmpty) {
        print('[Journey] ImportService: converted map null or empty');
        throw JourneyImportException('Invalid YAML structure');
      }
      final data = JourneyExportData.fromJson(map);
      print('[Journey] ImportService: parsed userName=${data.userName} events=${data.events.length}');
      return data;
    } on YamlException catch (e) {
      print('[Journey] ImportService: YamlException ${e.message}');
      throw JourneyImportException('Invalid YAML: ${e.message}');
    }
  }

  dynamic _convert(dynamic node) {
    if (node is YamlMap) {
      final result = <dynamic, dynamic>{};
      node.forEach((k, v) {
        result[k] = v is YamlMap || v is YamlList ? _convert(v) : v;
      });
      return result;
    }
    if (node is YamlList) {
      return node.map((e) => e is YamlMap || e is YamlList ? _convert(e) : e).toList();
    }
    return node;
  }
}

class JourneyImportException implements Exception {
  final String message;
  JourneyImportException(this.message);
  @override
  String toString() => message;
}
