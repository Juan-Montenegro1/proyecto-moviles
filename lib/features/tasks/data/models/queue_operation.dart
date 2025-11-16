import 'dart:convert';

/// Enum para tipos de operaciones
enum QueueOperationType { create, update, delete }

extension QueueOperationTypeExtension on QueueOperationType {
  String toShortString() {
    return toString().split('.').last.toUpperCase();
  }

  static QueueOperationType fromString(String value) {
    return QueueOperationType.values.firstWhere(
      (e) => e.toShortString() == value.toUpperCase(),
      orElse: () => QueueOperationType.create,
    );
  }
}

/// Model for queued operations to sync with server
class QueueOperation {
  final String id;
  final String entity;
  final String entityId;
  final QueueOperationType operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attemptCount;
  String? lastError;
  bool isProcessing;

  QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
    this.isProcessing = false,
  });

  /// Create from SQLite row
  factory QueueOperation.fromSqflite(Map<String, dynamic> map) {
    return QueueOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      operation: QueueOperationTypeExtension.fromString(map['op'] as String),
      payload: _parsePayload(map['payload'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  /// Convert to SQLite format
  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': operation.toShortString(),
      'payload': _encodePayload(payload),
      'created_at': createdAt.millisecondsSinceEpoch,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  /// Parse JSON payload
  static Map<String, dynamic> _parsePayload(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Encode payload to JSON string
  static String _encodePayload(Map<String, dynamic> payload) {
    try {
      return jsonEncode(payload);
    } catch (e) {
      return '{}';
    }
  }

  @override
  String toString() =>
      'QueueOperation(id: $id, entity: $entity, op: ${operation.toShortString()}, attempts: $attemptCount)';
}
