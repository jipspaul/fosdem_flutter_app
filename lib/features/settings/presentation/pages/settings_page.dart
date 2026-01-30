import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../journey/domain/models/journey_export_model.dart';
import '../../../journey/presentation/bloc/journey_bloc.dart';
import '../../../journey/presentation/bloc/journey_event.dart';
import '../../../journey/presentation/bloc/journey_state.dart';
import '../../../journey/data/services/journey_export_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const JourneyExportImportSection(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Auto Sync'),
            subtitle: const Text('Automatically sync schedule'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            subtitle: const Text('App appearance'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Reusable section for export/import journey (YAML). Use in Settings.
class JourneyExportImportSection extends StatefulWidget {
  const JourneyExportImportSection({Key? key}) : super(key: key);

  @override
  State<JourneyExportImportSection> createState() => _JourneyExportImportSectionState();
}

class _JourneyExportImportSectionState extends State<JourneyExportImportSection> {
  final _importUrlController = TextEditingController();
  final _exportService = JourneyExportService();
  bool _isImporting = false;
  int _prevImportedCount = 0;

  @override
  void dispose() {
    _importUrlController.dispose();
    super.dispose();
  }

  Future<void> _exportJourney(BuildContext context) async {
    final state = context.read<JourneyBloc>().state;
    if (state is! JourneyLoaded) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Load your journey first')),
        );
      }
      return;
    }
    try {
      final yaml = _exportService.buildYamlFromJourney(state);
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${dir.path}/journey.yaml'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importFromUrl(BuildContext context) async {
    final url = _importUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a URL')),
      );
      return;
    }
    setState(() => _isImporting = true);
    context.read<JourneyBloc>().add(ImportJourneyFromUrl(url));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JourneyBloc, JourneyState>(
      listener: (context, state) {
        if (state is JourneyLoaded) {
          if (state.importError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.importError!),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    context.read<JourneyBloc>().add(const ClearImportError());
                  },
                ),
              ),
            );
          } else if (_isImporting && state.importedJourneys.length > _prevImportedCount) {
            _prevImportedCount = state.importedJourneys.length;
            setState(() => _isImporting = false);
            _importUrlController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Journey imported'), backgroundColor: Colors.green),
            );
          }
        }
        if (state is! JourneyLoading && _isImporting && state is! JourneyLoaded) {
          setState(() => _isImporting = false);
        }
      },
      buildWhen: (prev, curr) {
        if (curr is JourneyLoaded && prev is JourneyLoaded) {
          return prev.importedJourneys != curr.importedJourneys ||
              prev.importError != curr.importError;
        }
        return true;
      },
      builder: (context, state) {
        final isLoaded = state is JourneyLoaded;
        final journeyState = state is JourneyLoaded ? state : null;
        final imported = journeyState?.importedJourneys ?? {};
        if (state is JourneyLoaded && !_isImporting) {
          _prevImportedCount = state.importedJourneys.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.route),
              title: Text('Journey'),
              subtitle: Text('Export or import journey (YAML)'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: isLoaded ? () => _exportJourney(context) : null,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Export Journey'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Import from URL',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _importUrlController,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/journey.yaml',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    enabled: !_isImporting,
                    onSubmitted: (_) => _importFromUrl(context),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isImporting ? null : () => _importFromUrl(context),
                    icon: _isImporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isImporting ? 'Importing...' : 'Import Journey'),
                  ),
                ],
              ),
            ),
            if (imported.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Imported Journeys',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ...imported.entries.map((e) => _ImportedJourneyTile(importKey: e.key, data: e.value)),
            ],
          ],
        );
      },
    );
  }
}

class _ImportedJourneyTile extends StatelessWidget {
  final String importKey;
  final JourneyExportData data;

  const _ImportedJourneyTile({required this.importKey, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: data.userPictureUrl != null && data.userPictureUrl!.isNotEmpty
            ? NetworkImage(data.userPictureUrl!)
            : null,
        child: data.userPictureUrl == null || data.userPictureUrl!.isEmpty
            ? Text((data.userName.isNotEmpty ? data.userName[0] : '?').toUpperCase())
            : null,
      ),
      title: Text(data.userName),
      subtitle: Text('${data.events.length} events'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          context.read<JourneyBloc>().add(RemoveImportedJourney(importKey));
        },
      ),
    );
  }
}
