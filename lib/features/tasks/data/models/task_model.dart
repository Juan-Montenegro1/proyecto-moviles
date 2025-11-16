import 'package:taller_flutter/features/tasks/domain/entities/task.dart';

/// TaskModel for data layer - used for serialization/deserialization
class TaskModel extends Task {
  TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.isCompleted,
    required super.updatedAt,
    super.isDeleted = false,
  });

  /// Create TaskModel from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['completed'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      isDeleted: (json['deleted'] as int? ?? 0) == 1,
    );
  }

  /// Create TaskModel from SQLite row
  factory TaskModel.fromSqflite(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: (map['completed'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['deleted'] as int? ?? 0) == 1,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': isCompleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to SQLite format
  Map<String, dynamic> toSqflite() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': isCompleted ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
      'deleted': isDeleted ? 1 : 0,
    };
  }

  /// Convert from Task entity to TaskModel
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: task.isCompleted,
      updatedAt: task.updatedAt,
      isDeleted: task.isDeleted,
    );
  }
}
