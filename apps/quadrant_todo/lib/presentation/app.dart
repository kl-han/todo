import 'package:flutter/material.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// v0.1 application shell: proves the UI-to-backend path end to end by
/// showing the health report of whichever backend bootstrap connected.
/// The real three-tab presentation lands in v0.3 (Linux) and v0.4 (iOS).
class QuadrantTodoApp extends StatelessWidget {
  const QuadrantTodoApp({super.key, required this.connection});

  final BackendConnection connection;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quadrant Todo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: _HealthScreen(connection: connection),
    );
  }
}

class _HealthScreen extends StatelessWidget {
  const _HealthScreen({required this.connection});

  final BackendConnection connection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quadrant Todo')),
      body: Center(
        child: FutureBuilder(
          future: connection.client.health(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Backend unreachable: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final report = snapshot.data!;
            return Text(
              'Connected to ${report.backend} backend\n'
              'API ${report.apiVersion}, schema ${report.schemaVersion}',
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }
}
