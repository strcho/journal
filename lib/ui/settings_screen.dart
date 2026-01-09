import 'package:flutter/material.dart';

import '../security/app_lock_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appLockService});

  final AppLockService appLockService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _available = false;
  bool _loading = true;
  final Map<Duration, String> _timeoutOptions = {
    Duration.zero: 'Immediately',
    const Duration(minutes: 1): 'After 1 minute',
    const Duration(minutes: 5): 'After 5 minutes',
    const Duration(minutes: 15): 'After 15 minutes',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final available = await widget.appLockService.canAuthenticate();
    if (!mounted) {
      return;
    }
    setState(() {
      _available = available;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: widget.appLockService.enabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: const Text('App lock'),
                subtitle: Text(
                  _loading
                      ? 'Checking device security...'
                      : _available
                          ? 'Require biometrics or device passcode'
                          : 'Device authentication is not available',
                ),
                value: enabled,
                onChanged: _loading || !_available ? null : _toggleLock,
              );
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: widget.appLockService.enabled,
            builder: (context, enabled, _) {
              return ValueListenableBuilder<Duration>(
                valueListenable: widget.appLockService.timeout,
                builder: (context, timeout, child) {
                  return InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Lock after',
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Duration>(
                        value: _timeoutOptions.containsKey(timeout)
                            ? timeout
                            : Duration.zero,
                        isExpanded: true,
                        items: _timeoutOptions.entries
                            .map(
                              (entry) => DropdownMenuItem<Duration>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: enabled && !_loading && _available
                            ? _updateTimeout
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'App lock tips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '- Uses device biometrics or passcode\n'
                    '- Lock after only applies when the app is in background\n'
                    '- Keep device security enabled for best protection',
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _showAppLockHelp,
                      child: const Text('Learn more'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLock(bool value) async {
    if (value == widget.appLockService.enabled.value) {
      return;
    }

    final success = await widget.appLockService.authenticate(
      reason: value ? 'Enable app lock' : 'Disable app lock',
    );
    if (!success || !mounted) {
      return;
    }

    await widget.appLockService.setEnabled(value);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateTimeout(Duration? value) async {
    if (value == null) {
      return;
    }
    await widget.appLockService.setTimeout(value);
  }

  Future<void> _showAppLockHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App lock help'),
        content: const Text(
          'App lock requires device authentication. If you disable biometrics '
          'or passcode at the system level, app lock will stop working.\n\n'
          'Lock after only triggers when the app is backgrounded. It does not '
          'lock while you are actively using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
