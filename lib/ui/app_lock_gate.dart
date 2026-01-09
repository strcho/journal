import 'package:flutter/material.dart';
import 'package:my_day_one/l10n/app_localizations.dart';

import '../security/app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.appLockService,
    required this.child,
  });

  final AppLockService appLockService;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _needsAuth = false;
  bool _authInProgress = false;
  DateTime? _lastInactiveAt;
  bool _initialized = false;
  bool _wasEnabled = false;
  DateTime? _enableGraceUntil;
  late final VoidCallback _enabledListener;
  late final VoidCallback _timeoutListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enabledListener = _handleEnabledChanged;
    _timeoutListener = _handleTimeoutChanged;
    widget.appLockService.enabled.addListener(_enabledListener);
    widget.appLockService.timeout.addListener(_timeoutListener);
    _handleEnabledChanged();
    _initialized = true;
  }

  @override
  void dispose() {
    widget.appLockService.enabled.removeListener(_enabledListener);
    widget.appLockService.timeout.removeListener(_timeoutListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.appLockService.enabled.value) {
      return;
    }
    if (_authInProgress) {
      return;
    }
    if (_enableGraceUntil != null) {
      if (DateTime.now().isBefore(_enableGraceUntil!)) {
        return;
      }
      _enableGraceUntil = null;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastInactiveAt = DateTime.now();
      if (widget.appLockService.timeout.value == Duration.zero) {
        _needsAuth = true;
        setState(() => _locked = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  void _handleEnabledChanged() {
    final enabled = widget.appLockService.enabled.value;
    final wasEnabled = _wasEnabled;
    _wasEnabled = enabled;
    if (!enabled) {
      _needsAuth = false;
      _lastInactiveAt = null;
      setState(() => _locked = false);
      return;
    }

    if (_initialized && !wasEnabled) {
      // Just enabled by the user; avoid immediate lock.
      _needsAuth = false;
      _lastInactiveAt = null;
      _enableGraceUntil = DateTime.now().add(const Duration(seconds: 3));
      setState(() => _locked = false);
      return;
    }

    _needsAuth = true;
    _lastInactiveAt = DateTime.now();
    setState(() => _locked = true);
    _attemptUnlock();
  }

  void _handleTimeoutChanged() {
    if (!widget.appLockService.enabled.value) {
      return;
    }
    setState(() {});
  }

  void _handleResume() {
    if (!widget.appLockService.enabled.value) {
      return;
    }
    if (_authInProgress) {
      return;
    }
    if (_enableGraceUntil != null) {
      if (DateTime.now().isBefore(_enableGraceUntil!)) {
        return;
      }
      _enableGraceUntil = null;
    }
    final timeout = widget.appLockService.timeout.value;
    if (timeout == Duration.zero) {
      _needsAuth = true;
      setState(() => _locked = true);
      _attemptUnlock();
      return;
    }

    final lastInactive = _lastInactiveAt;
    _lastInactiveAt = null;
    if (lastInactive == null) {
      return;
    }
    final elapsed = DateTime.now().difference(lastInactive);
    if (elapsed >= timeout) {
      _needsAuth = true;
      setState(() => _locked = true);
      _attemptUnlock();
    } else {
      _needsAuth = false;
      setState(() => _locked = false);
    }
  }

  Future<void> _attemptUnlock() async {
    if (!_needsAuth && _locked) {
      _needsAuth = true;
    }
    if (!_needsAuth || _authInProgress) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    _authInProgress = true;
    var success = false;
    try {
      final canAuth = await widget.appLockService.canAuthenticate();
      if (!canAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.appLockSubtitleUnavailable)),
          );
        }
        return;
      }
      success = await widget.appLockService.authenticate(
        reason: l10n.unlockReason,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appLockSubtitleUnavailable)),
        );
      }
      return;
    } finally {
      _authInProgress = false;
    }
    if (!mounted) {
      return;
    }
    if (success) {
      _needsAuth = false;
      _lastInactiveAt = null;
      setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) {
      return widget.child;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.journalLockedTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.journalLockedBody),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _attemptUnlock,
                  icon: const Icon(Icons.lock_open),
                  label: Text(AppLocalizations.of(context)!.unlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
