import 'package:taller_flutter/features/tasks/domain/entities/task.dart';
import 'package:taller_flutter/features/tasks/domain/repositories/task_repository.dart';

/// Get all tasks use case
class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<List<Task>> call() => repository.getTasks();
}

/// Fetch tasks from remote API
class FetchTasksFromRemoteUseCase {
  final TaskRepository repository;

  FetchTasksFromRemoteUseCase(this.repository);

  Future<List<Task>> call() => repository.fetchTasksFromRemote();
}

/// Get task by ID use case
class GetTaskByIdUseCase {
  final TaskRepository repository;

  GetTaskByIdUseCase(this.repository);

  Future<Task> call(String id) => repository.getTaskById(id);
}

/// Create task use case
class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<Task> call(Task task) => repository.createTask(task);
}

/// Update task use case
class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  Future<Task> call(Task task) => repository.updateTask(task);
}

/// Delete task use case
class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  Future<void> call(String id) => repository.deleteTask(id);
}

/// Get filtered tasks use case
class GetFilteredTasksUseCase {
  final TaskRepository repository;

  GetFilteredTasksUseCase(this.repository);

  Future<List<Task>> call({bool? completed}) => repository.getFilteredTasks(completed: completed);
}
