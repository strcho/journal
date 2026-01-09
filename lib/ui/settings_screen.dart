import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final timeoutOptions = {
      Duration.zero: l10n.lockAfterImmediately,
      const Duration(minutes: 1): l10n.lockAfter1Min,
      const Duration(minutes: 5): l10n.lockAfter5Min,
      const Duration(minutes: 15): l10n.lockAfter15Min,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: widget.appLockService.enabled,
            builder: (context, enabled, _) {
              return SwitchListTile(
                title: Text(l10n.appLockTitle),
                subtitle: Text(
                  _loading
                      ? l10n.appLockSubtitleChecking
                      : _available
                          ? l10n.appLockSubtitleEnabled
                          : l10n.appLockSubtitleUnavailable,
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
                    decoration: InputDecoration(
                      labelText: l10n.lockAfterLabel,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Duration>(
                        value: timeoutOptions.containsKey(timeout)
                            ? timeout
                            : Duration.zero,
                        isExpanded: true,
                        items: timeoutOptions.entries
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
                        l10n.appLockTipsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.appLockTipsBody),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _showAppLockHelp,
                      child: Text(l10n.learnMore),
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

    final l10n = AppLocalizations.of(context)!;
    final success = await widget.appLockService.authenticate(
      reason: value ? l10n.enableAppLockReason : l10n.disableAppLockReason,
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.appLockHelpTitle),
          content: Text(l10n.appLockHelpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
        );
      },
    );
  }
}
