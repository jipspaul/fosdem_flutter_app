import 'package:flutter/material.dart';
import '../../../core/services/sync_queue_service.dart';
import '../../../data/models/sync_operation.dart';

class SyncStatusWidget extends StatelessWidget {
  final SyncQueueStatus status;
  final VoidCallback? onRetryFailed;
  final VoidCallback? onViewDetails;

  const SyncStatusWidget({
    super.key,
    required this.status,
    this.onRetryFailed,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (status.pendingCount == 0 && status.failedCount == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.isProcessing ? Icons.sync : Icons.sync_problem,
                  color: status.failedCount > 0 ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.isProcessing ? 'Syncing...' : 'Sync Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onViewDetails != null)
                  IconButton(icon: const Icon(Icons.info_outline), onPressed: onViewDetails),
              ],
            ),
            const SizedBox(height: 12),
            if (status.pendingCount > 0)
              _buildStatusRow(context, Icons.schedule, '${status.pendingCount} pending', Colors.blue),
            if (status.failedCount > 0) ...[
              const SizedBox(height: 8),
              _buildStatusRow(context, Icons.error_outline, '${status.failedCount} failed', Colors.red),
              if (onRetryFailed != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetryFailed,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Failed'),
                ),
              ],
            ],
            if (status.isProcessing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
      ],
    );
  }
}

class SyncProgressIndicator extends StatelessWidget {
  final bool isVisible;
  final String? message;

  const SyncProgressIndicator({super.key, required this.isVisible, this.message});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(message ?? 'Syncing...', style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class SyncButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? label;

  const SyncButton({super.key, required this.onPressed, this.isLoading = false, this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync),
      label: Text(label ?? 'Sync Now'),
    );
  }
}

class SyncOperationsList extends StatelessWidget {
  final List<SyncOperation> operations;
  final Function(String)? onRetry;
  final Function(String)? onCancel;

  const SyncOperationsList({super.key, required this.operations, this.onRetry, this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (operations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
              const SizedBox(height: 16),
              Text('All synced!', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('No pending operations', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: operations.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final op = operations[index];
        return ListTile(
          leading: _buildStatusIcon(op.status),
          title: Text(_getOperationTitle(op.type)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Priority: ${op.priority}'),
              if (op.error != null) Text(op.error!, style: TextStyle(color: Colors.red[300], fontSize: 12)),
              if (op.retryCount > 0) Text('Retry: ${op.retryCount}/${op.maxRetries}'),
            ],
          ),
          trailing: _buildActions(context, op),
        );
      },
    );
  }

  Widget _buildStatusIcon(SyncOperationStatus status) {
    switch (status) {
      case SyncOperationStatus.pending:
        return const Icon(Icons.schedule, color: Colors.blue);
      case SyncOperationStatus.inProgress:
        return const CircularProgressIndicator();
      case SyncOperationStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncOperationStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case SyncOperationStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey);
    }
  }

  String _getOperationTitle(SyncOperationType type) {
    switch (type) {
      case SyncOperationType.addFavorite:
        return 'Add Favorite';
      case SyncOperationType.removeFavorite:
        return 'Remove Favorite';
      case SyncOperationType.updateEvent:
        return 'Update Event';
      case SyncOperationType.deleteEvent:
        return 'Delete Event';
      case SyncOperationType.custom:
        return 'Custom Operation';
    }
  }

  Widget? _buildActions(BuildContext context, SyncOperation op) {
    if (op.isFailed && onRetry != null) {
      return IconButton(icon: const Icon(Icons.refresh), onPressed: () => onRetry!(op.id));
    }
    if (op.isPending && onCancel != null) {
      return IconButton(icon: const Icon(Icons.close), onPressed: () => onCancel!(op.id));
    }
    return null;
  }
}
