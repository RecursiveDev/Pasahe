import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../models/connectivity_status.dart';
import '../../services/connectivity/connectivity_service.dart';

/// A widget that displays the current offline status.
///
/// Shows a compact banner when the device is offline or has limited
/// connectivity, providing visual feedback to users about their
/// connection status.
class OfflineIndicatorWidget extends StatefulWidget {
  /// Child widget to display below the indicator.
  final Widget? child;

  /// Whether to show the indicator with animation.
  final bool animate;

  const OfflineIndicatorWidget({super.key, this.child, this.animate = true});

  @override
  State<OfflineIndicatorWidget> createState() => _OfflineIndicatorWidgetState();
}

class _OfflineIndicatorWidgetState extends State<OfflineIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late final ConnectivityService _connectivityService;
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  StreamSubscription<ConnectivityStatus>? _subscription;
  ConnectivityStatus _status = ConnectivityStatus.online;

  @override
  void initState() {
    super.initState();
    _connectivityService = getIt<ConnectivityService>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Get initial status
    _status = _connectivityService.lastKnownStatus;
    _updateAnimation();

    // Listen for changes
    _subscription = _connectivityService.connectivityStream.listen((status) {
      if (mounted) {
        setState(() => _status = status);
        _updateAnimation();
      }
    });
  }

  void _updateAnimation() {
    if (_status.isOffline || _status.isLimited) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child == null) {
      return _buildIndicator(context);
    }

    return Column(
      children: [
        _buildAnimatedIndicator(context),
        Expanded(child: widget.child!),
      ],
    );
  }

  Widget _buildAnimatedIndicator(BuildContext context) {
    if (!widget.animate) {
      return _status.isOffline || _status.isLimited
          ? _buildIndicator(context)
          : const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: _buildIndicator(context),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOffline = _status.isOffline;
    final backgroundColor = isOffline
        ? colorScheme.surfaceContainerHighest
        : colorScheme.tertiaryContainer;
    final textColor = isOffline
        ? colorScheme.onSurface
        : colorScheme.onTertiaryContainer;
    final icon = isOffline
        ? Icons.cloud_off
        : Icons.signal_wifi_statusbar_4_bar;
    final text = isOffline
        ? 'You are offline. Showing cached data.'
        : 'Limited connectivity. Some features may be unavailable.';

    return Semantics(
      label: text,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simpler offline indicator that just shows an icon badge.
class OfflineIndicatorBadge extends StatefulWidget {
  /// Size of the badge.
  final double size;

  const OfflineIndicatorBadge({super.key, this.size = 24});

  @override
  State<OfflineIndicatorBadge> createState() => _OfflineIndicatorBadgeState();
}

class _OfflineIndicatorBadgeState extends State<OfflineIndicatorBadge> {
  late final ConnectivityService _connectivityService;
  StreamSubscription<ConnectivityStatus>? _subscription;
  ConnectivityStatus _status = ConnectivityStatus.online;

  @override
  void initState() {
    super.initState();
    _connectivityService = getIt<ConnectivityService>();
    _status = _connectivityService.lastKnownStatus;

    _subscription = _connectivityService.connectivityStream.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status.isOnline) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isOffline = _status.isOffline;

    return Semantics(
      label: isOffline ? 'Offline' : 'Limited connectivity',
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: isOffline
              ? colorScheme.surfaceContainerHighest
              : colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isOffline ? Icons.cloud_off : Icons.signal_wifi_statusbar_4_bar,
          size: widget.size * 0.6,
          color: isOffline
              ? colorScheme.onSurface
              : colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

/// A wrapper that shows a snackbar when connectivity changes.
class ConnectivitySnackbarWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivitySnackbarWrapper({super.key, required this.child});

  @override
  State<ConnectivitySnackbarWrapper> createState() =>
      _ConnectivitySnackbarWrapperState();
}

class _ConnectivitySnackbarWrapperState
    extends State<ConnectivitySnackbarWrapper> {
  late final ConnectivityService _connectivityService;
  StreamSubscription<ConnectivityStatus>? _subscription;
  ConnectivityStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _connectivityService = getIt<ConnectivityService>();
    _previousStatus = _connectivityService.lastKnownStatus;

    _subscription = _connectivityService.connectivityStream.listen((status) {
      if (_previousStatus != null && _previousStatus != status) {
        _showConnectivitySnackbar(status);
      }
      _previousStatus = status;
    });
  }

  void _showConnectivitySnackbar(ConnectivityStatus status) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String message;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case ConnectivityStatus.online:
        message = 'Back online';
        backgroundColor = Colors.green;
        icon = Icons.cloud_done;
        break;
      case ConnectivityStatus.offline:
        message = 'You are offline';
        backgroundColor = colorScheme.surfaceContainerHighest;
        icon = Icons.cloud_off;
        break;
      case ConnectivityStatus.limited:
        message = 'Limited connectivity';
        backgroundColor = colorScheme.tertiaryContainer;
        icon = Icons.signal_wifi_statusbar_4_bar;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
