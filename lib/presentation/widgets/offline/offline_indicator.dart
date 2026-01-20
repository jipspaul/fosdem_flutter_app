import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';

class OfflineIndicator extends StatelessWidget {
  final ConnectivityStatus status;
  final VoidCallback? onTap;

  const OfflineIndicator({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStatusColor(), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ConnectivityStatus.offline:
        return Colors.red;
      case ConnectivityStatus.wifi:
        return Colors.green;
      case ConnectivityStatus.mobile:
        return Colors.orange;
      case ConnectivityStatus.online:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case ConnectivityStatus.offline:
        return Icons.cloud_off;
      case ConnectivityStatus.wifi:
        return Icons.wifi;
      case ConnectivityStatus.mobile:
        return Icons.signal_cellular_alt;
      case ConnectivityStatus.online:
        return Icons.cloud_done;
    }
  }

  String _getStatusText() {
    switch (status) {
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.wifi:
        return 'WiFi';
      case ConnectivityStatus.mobile:
        return 'Mobile';
      case ConnectivityStatus.online:
        return 'Online';
    }
  }
}

class OfflineFloatingIndicator extends StatelessWidget {
  final ConnectivityStatus status;
  final VoidCallback? onRetry;

  const OfflineFloatingIndicator({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status != ConnectivityStatus.offline) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'re offline. Viewing cached data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
              if (onRetry != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                  onPressed: onRetry,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineSnackBar {
  static void show(BuildContext context, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('You are currently offline')),
          ],
        ),
        action: onRetry != null ? SnackBarAction(label: 'Retry', onPressed: onRetry) : null,
        backgroundColor: Colors.grey[900],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showBackOnline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.white),
            SizedBox(width: 12),
            Text('Back online'),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
