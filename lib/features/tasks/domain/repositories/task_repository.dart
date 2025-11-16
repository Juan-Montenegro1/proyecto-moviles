import 'package:taller_flutter/features/tasks/domain/entities/task.dart';

/// Abstract repository for task operations
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<List<Task>> fetchTasksFromRemote();
  Future<Task> getTaskById(String id);
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<List<Task>> getFilteredTasks({bool? completed});
}
