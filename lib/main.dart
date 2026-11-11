import 'package:flutter/material.dart';

void main() => runApp(const DrumCoachApp());

class DrumCoachApp extends StatelessWidget {
  const DrumCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drum Coach',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(body: Center(child: Text('Drum Coach'))),
    );
  }
}
