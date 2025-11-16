/// Task entity representing a task in the domain layer
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime updatedAt;
  final bool isDeleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          updatedAt == other.updatedAt &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      isCompleted.hashCode ^
      updatedAt.hashCode ^
      isDeleted.hashCode;

  @override
  String toString() =>
      'Task(id: $id, title: $title, isCompleted: $isCompleted, updatedAt: $updatedAt)';
}
