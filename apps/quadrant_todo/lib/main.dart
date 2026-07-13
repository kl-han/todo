import 'package:flutter/widgets.dart';

import 'bootstrap/local_bootstrap.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // v0.1 always boots in local mode; the backend-mode selector arrives in
  // v0.7 and switches between local_bootstrap and remote_bootstrap.
  final connection = await bootstrapLocalBackend();
  runApp(QuadrantTodoApp(connection: connection));
}
