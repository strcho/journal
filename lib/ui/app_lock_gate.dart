import 'package:flutter/material.dart';

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
    if (!enabled) {
      _needsAuth = false;
      _lastInactiveAt = null;
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
    if (!_needsAuth || _authInProgress) {
      return;
    }

    _authInProgress = true;
    final success = await widget.appLockService.authenticate(
      reason: 'Unlock your journal',
    );
    if (!mounted) {
      return;
    }
    _authInProgress = false;
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
                  'Journal locked',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Authenticate to continue.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _attemptUnlock,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
