import 'package:flutter/material.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

import '../bootstrap/backend_selector.dart';
import '../platform/keyboard.dart';
import '../state/app_state.dart';
import 'matrix_screen.dart';
import 'settings_screen.dart';
import 'tags_screen.dart';
import 'tasks_screen.dart';

/// Three-tab shell: Matrix, Tasks, Tags. Alt+1/2/3 switch tabs; h/j/k/l
/// move focus; Enter activates the focused tile. On app resume the
/// embedded backend's health is re-verified.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.state,
    required this.settingsStore,
    required this.credentialStore,
  });

  final AppState state;
  final SettingsStore settingsStore;
  final CredentialStore credentialStore;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Lifecycle notifications may be skipped entirely; this is a best-
    // effort recovery hook, not a correctness dependency.
    if (lifecycle == AppLifecycleState.resumed) {
      widget.state.ensureBackendHealthy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: appShortcuts(),
      child: Actions(
        actions: {
          SwitchTabIntent: CallbackAction<SwitchTabIntent>(
            onInvoke: (intent) => setState(() => _tab = intent.index),
          ),
          MoveFocusIntent: MoveFocusAction(),
        },
        child: Focus(
          autofocus: true,
          child: ListenableBuilder(
            listenable: widget.state,
            builder: (context, _) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Quadrant Todo'),
                  actions: [
                    if (widget.state.loading)
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: widget.state.refresh,
                    ),
                    IconButton(
                      key: const ValueKey('open-settings'),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Backend settings',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SettingsScreen(
                            state: widget.state,
                            settingsStore: widget.settingsStore,
                            credentialStore: widget.credentialStore,
                            applySettings: () async {
                              final connection = await bootstrapFromSettings(
                                settingsStore: widget.settingsStore,
                                credentialStore: widget.credentialStore,
                              );
                              await widget.state.switchConnection(connection);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    if (widget.state.error != null)
                      MaterialBanner(
                        key: const ValueKey('error-banner'),
                        content: Text(widget.state.error!),
                        leading: const Icon(Icons.cloud_off),
                        actions: [
                          TextButton(
                            onPressed: widget.state.refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: switch (_tab) {
                        0 => MatrixScreen(state: widget.state),
                        1 => TasksScreen(state: widget.state),
                        _ => TagsScreen(state: widget.state),
                      },
                    ),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (index) =>
                      setState(() => _tab = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view),
                      label: 'Matrix',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.checklist),
                      label: 'Tasks',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.label),
                      label: 'Tags',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
