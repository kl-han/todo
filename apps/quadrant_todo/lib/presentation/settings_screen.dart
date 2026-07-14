import 'package:flutter/material.dart';
import 'package:quadrant_backend_host/quadrant_backend_host.dart';

import '../state/app_state.dart';

/// Backend settings sheet: choose local or remote mode, configure the
/// remote server, test connectivity, and apply — with an explicit
/// dataset-switch confirmation, because changing modes changes the source
/// of truth (nothing is merged or copied).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.state,
    required this.settingsStore,
    required this.credentialStore,
    required this.applySettings,
  });

  final AppState state;
  final SettingsStore settingsStore;
  final CredentialStore credentialStore;

  /// Re-bootstraps the app onto the saved settings.
  final Future<void> Function() applySettings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BackendSettings _current = widget.settingsStore.load();
  late BackendMode _mode = _current.mode;
  late final TextEditingController _url =
      TextEditingController(text: _current.remoteUrl?.toString() ?? '');
  late final TextEditingController _vault =
      TextEditingController(text: _current.remoteVault);
  final TextEditingController _token = TextEditingController();

  RemoteDiagnostics? _diagnostics;
  bool _testing = false;

  RemoteBackendProfile? _profile() {
    final url = Uri.tryParse(_url.text.trim());
    if (url == null || !url.hasScheme) return null;
    final vault = _vault.text.trim();
    if (vault.isEmpty) return null;
    return RemoteBackendProfile(baseUrl: url, vaultId: vault);
  }

  Future<void> _test() async {
    final profile = _profile();
    if (profile == null) return;
    setState(() {
      _testing = true;
      _diagnostics = null;
    });
    final token = _token.text.trim().isEmpty
        ? await widget.credentialStore.read(profile.credentialKey) ?? ''
        : _token.text.trim();
    final result = await diagnoseRemoteBackend(profile, token);
    if (mounted) {
      setState(() {
        _testing = false;
        _diagnostics = result;
      });
    }
  }

  Future<void> _save() async {
    final switching = _mode != _current.mode ||
        (_mode == BackendMode.remote &&
            (_url.text.trim() != (_current.remoteUrl?.toString() ?? '') ||
                _vault.text.trim() != _current.remoteVault));

    if (switching) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('switch-confirm'),
          title: const Text('Switch backend?'),
          content: const Text(
            'Switching changes which dataset you see. Local and remote '
            'data are separate; nothing is merged, copied, or '
            'synchronized.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('switch-confirm-yes'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Switch'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (_mode == BackendMode.local) {
      widget.settingsStore.save(const BackendSettings.local());
    } else {
      final profile = _profile();
      if (profile == null) return;
      final settings = BackendSettings.remote(
        remoteUrl: profile.baseUrl,
        remoteVault: profile.vaultId,
      );
      widget.settingsStore.save(settings);
      final token = _token.text.trim();
      if (token.isNotEmpty) {
        await widget.credentialStore.write(profile.credentialKey, token);
      }
    }
    _current = widget.settingsStore.load();
    await widget.applySettings();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics = _diagnostics;
    return Scaffold(
      appBar: AppBar(title: const Text('Backend settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RadioListTile<BackendMode>(
            key: const ValueKey('mode-local'),
            title: const Text('Local (on this device)'),
            subtitle: const Text('Works offline; data stays here.'),
            value: BackendMode.local,
            groupValue: _mode,
            onChanged: (mode) => setState(() => _mode = mode!),
          ),
          RadioListTile<BackendMode>(
            key: const ValueKey('mode-remote'),
            title: const Text('Remote (your server)'),
            subtitle: const Text('Online only; explicit error when '
                'unreachable.'),
            value: BackendMode.remote,
            groupValue: _mode,
            onChanged: (mode) => setState(() => _mode = mode!),
          ),
          if (_mode == BackendMode.remote) ...[
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('remote-url'),
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://todo.example.net',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('remote-vault'),
              controller: _vault,
              decoration: const InputDecoration(labelText: 'Vault'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('remote-token'),
              controller: _token,
              decoration: const InputDecoration(
                labelText: 'Bearer token',
                helperText:
                    'Stored in the platform secure storage; leave empty '
                    'to keep the saved one.',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('test-connection'),
                  onPressed: _testing ? null : _test,
                  icon: const Icon(Icons.network_check),
                  label: Text(_testing ? 'Testing…' : 'Test connection'),
                ),
                const SizedBox(width: 12),
                if (diagnostics != null)
                  Expanded(
                    child: Text(
                      diagnostics.ok
                          ? 'Connection OK — vault found.'
                          : diagnostics.detail ?? 'Connection failed.',
                      key: const ValueKey('diagnostics-result'),
                      style: TextStyle(
                        color: diagnostics.ok
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('settings-save'),
            onPressed: _save,
            child: const Text('Save'),
          ),
          const Divider(height: 32),
          SwitchListTile(
            key: const ValueKey('pref-tap-opens-editor'),
            title: const Text('Tap a task to edit'),
            subtitle: const Text(
              'Off: tapping a task toggles completion instead. The checkbox '
              'always toggles completion.',
            ),
            value: widget.state.tapOpensEditor,
            onChanged: (value) =>
                setState(() => widget.state.setTapOpensEditor(value)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _url.dispose();
    _vault.dispose();
    _token.dispose();
    super.dispose();
  }
}
