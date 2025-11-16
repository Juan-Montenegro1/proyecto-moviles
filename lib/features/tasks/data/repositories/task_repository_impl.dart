import 'package:taller_flutter/features/tasks/domain/entities/task.dart';
import 'package:taller_flutter/features/tasks/domain/repositories/task_repository.dart';

/// Implementation of TaskRepository
class TaskRepositoryImpl implements TaskRepository {
  // TODO: Inject dependencies (TasksApi, LocalDatabase)

  @override
  Future<List<Task>> getTasks() async {
    // TODO: Implement
    throw UnimplementedError();
  }

  @override
  Future<Task> getTaskById(int id) async {
    // TODO: Implement
    throw UnimplementedError();
  }

  @override
  Future<Task> createTask(Task task) async {
    // TODO: Implement
    throw UnimplementedError();
  }

  @override
  Future<Task> updateTask(Task task) async {
    // TODO: Implement
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTask(int id) async {
    // TODO: Implement
    throw UnimplementedError();
  }
}
