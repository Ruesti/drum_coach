import 'package:flutter/material.dart';

import '../data/guided_catalog.dart';

/// Temporary screen behind `/guided/:id` and `/guided/:id/play`.
class GuidedPlaceholder extends StatelessWidget {
  const GuidedPlaceholder({super.key, required this.id, this.play = false});
  final String id;
  final bool play;

  @override
  Widget build(BuildContext context) {
    final name = guidedCatalog.where((e) => e.id == id).map((e) => e.name);
    return Scaffold(
      appBar: AppBar(title: Text(name.isEmpty ? id : name.first)),
      body: Center(child: Text(play ? 'Coming soon (player)' : 'Coming soon')),
    );
  }
}
