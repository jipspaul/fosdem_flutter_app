import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  final ConnectivityStatus status;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status != ConnectivityStatus.offline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[900],
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No Internet Connection',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'You\'re viewing cached data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConnectivityBanner extends StatelessWidget {
  final ConnectivityStatus status;
  final bool showOnlineStatus;

  const ConnectivityBanner({
    super.key,
    required this.status,
    this.showOnlineStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ConnectivityStatus.offline) {
      return _buildOfflineBanner(context);
    }

    if (!showOnlineStatus) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green[700],
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Back Online',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[900],
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Offline Mode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final ConnectivityService connectivityService;
  final bool showBanner;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    required this.connectivityService,
    this.showBanner = true,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  ConnectivityStatus _status = ConnectivityStatus.online;
  bool _showOnlineStatus = false;

  @override
  void initState() {
    super.initState();
    _status = widget.connectivityService.currentStatus;
    widget.connectivityService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          final wasOffline = _status == ConnectivityStatus.offline;
          _status = status;
          
          if (wasOffline && status != ConnectivityStatus.offline) {
            _showOnlineStatus = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _showOnlineStatus = false;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showBanner)
          ConnectivityBanner(
            status: _status,
            showOnlineStatus: _showOnlineStatus,
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
