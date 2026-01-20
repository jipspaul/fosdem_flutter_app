import 'package:flutter/material.dart';

class TracksPage extends StatelessWidget {
  const TracksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracks'),
      ),
      body: const Center(
        child: Text('Browse by tracks'),
      ),
    );
  }
}
