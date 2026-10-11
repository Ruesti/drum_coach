import 'package:flutter/material.dart';

class MidiCalibrationScreen extends StatelessWidget {
  const MidiCalibrationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MIDI latency')),
        body: const Center(child: Text('Coming in the next task')),
      );
}
