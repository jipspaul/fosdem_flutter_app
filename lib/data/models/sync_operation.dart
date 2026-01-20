import 'package:equatable/equatable.dart';

enum SyncOperationType {
  addFavorite,
  removeFavorite,
  updateEvent,
  deleteEvent,
  custom,
}

enum SyncOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled,
}

class SyncOperation extends Equatable {
  final String id;
  final SyncOperationType type;
  final SyncOperationStatus status;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int retryCount;
  final int maxRetries;
  final String? error;
  final int priority;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.status,
    required this.data,
    required this.createdAt,
    this.completedAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.error,
    this.priority = 0,
  });

  SyncOperation copyWith({
    SyncOperationType? type,
    SyncOperationStatus? status,
    Map<String, dynamic>? data,
    DateTime? completedAt,
    int? retryCount,
    String? error,
    int? priority,
  }) {
    return SyncOperation(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      data: data ?? this.data,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
      error: error ?? this.error,
      priority: priority ?? this.priority,
    );
  }

  bool get canRetry => retryCount < maxRetries;
  bool get isPending => status == SyncOperationStatus.pending;
  bool get isCompleted => status == SyncOperationStatus.completed;
  bool get isFailed => status == SyncOperationStatus.failed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'retryCount': retryCount,
    'maxRetries': maxRetries,
    'error': error,
    'priority': priority,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    type: SyncOperationType.values.firstWhere((e) => e.name == json['type']),
    status: SyncOperationStatus.values.firstWhere((e) => e.name == json['status']),
    data: json['data'] as Map<String, dynamic>,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    retryCount: json['retryCount'] as int? ?? 0,
    maxRetries: json['maxRetries'] as int? ?? 3,
    error: json['error'] as String?,
    priority: json['priority'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [id, type, status, data, createdAt, completedAt, retryCount, error, priority];
}
