import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:taller_flutter/features/tasks/domain/entities/task.dart';
import 'package:taller_flutter/features/tasks/domain/repositories/task_repository.dart';
import 'package:taller_flutter/features/tasks/domain/usecases/task_usecases.dart';
import 'package:taller_flutter/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:taller_flutter/features/tasks/data/local/database.dart';
import 'package:taller_flutter/features/tasks/data/remote/tasks_api.dart';
import 'package:taller_flutter/core/database/database_manager.dart';

// ============ PROVIDERS FOR DEPENDENCIES ============

/// Local database provider - uses globally initialized database
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return getDatabase();
});

/// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Remote data source provider
final tasksRemoteDataSourceProvider = Provider<TasksRemoteDataSource>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  const baseUrl = 'http://10.0.2.2:3000'; // Android emulator localhost mapping
  return TasksRemoteDataSource(
    httpClient: httpClient,
    baseUrl: baseUrl,
  );
});

/// Task repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  final remoteDataSource = ref.watch(tasksRemoteDataSourceProvider);
  return TaskRepositoryImpl(
    localDatabase: localDb,
    remoteDataSource: remoteDataSource,
  );
});

// ============ USE CASES PROVIDERS ============

final getTasksUseCaseProvider = Provider<GetTasksUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetTasksUseCase(repository);
});

final getTaskByIdUseCaseProvider = Provider<GetTaskByIdUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetTaskByIdUseCase(repository);
});

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return CreateTaskUseCase(repository);
});

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return UpdateTaskUseCase(repository);
});

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return DeleteTaskUseCase(repository);
});

final getFilteredTasksUseCaseProvider = Provider<GetFilteredTasksUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetFilteredTasksUseCase(repository);
});

// ============ STATE PROVIDERS ============

/// Filter state provider
final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter.all;
});

/// Tasks list provider
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final filter = ref.watch(taskFilterProvider);
  final useCase = ref.watch(getFilteredTasksUseCaseProvider);
  
  switch (filter) {
    case TaskFilter.all:
      return useCase.call();
    case TaskFilter.pending:
      return useCase.call(completed: false);
    case TaskFilter.completed:
      return useCase.call(completed: true);
  }
});

/// Task detail provider
final taskDetailProvider = FutureProvider.family<Task, String>((ref, id) async {
  final useCase = ref.watch(getTaskByIdUseCaseProvider);
  return useCase.call(id);
});

/// Create/Update task controller
final taskControllerProvider = StateNotifierProvider<TaskController, AsyncValue<void>>(
  (ref) => TaskController(
    ref: ref,
    createUseCase: ref.watch(createTaskUseCaseProvider),
    updateUseCase: ref.watch(updateTaskUseCaseProvider),
    deleteUseCase: ref.watch(deleteTaskUseCaseProvider),
  ),
);

// ============ ASYNC ACTIONS ============

final createTaskActionProvider = FutureProvider.family<Task, Task>((ref, task) async {
  final useCase = ref.watch(createTaskUseCaseProvider);
  final newTask = await useCase.call(task);
  ref.invalidate(tasksProvider);
  return newTask;
});

final updateTaskActionProvider = FutureProvider.family<Task, Task>((ref, task) async {
  final useCase = ref.watch(updateTaskUseCaseProvider);
  final updatedTask = await useCase.call(task);
  ref.invalidate(tasksProvider);
  ref.invalidate(taskDetailProvider(task.id));
  return updatedTask;
});

final deleteTaskActionProvider = FutureProvider.family<void, String>((ref, id) async {
  final useCase = ref.watch(deleteTaskUseCaseProvider);
  await useCase.call(id);
  ref.invalidate(tasksProvider);
  ref.invalidate(taskDetailProvider(id));
});

final refreshTasksProvider = FutureProvider<void>((ref) async {
  // Refresh tasks from local database
  ref.invalidate(tasksProvider);
  // Could also sync from remote here
});

/// Task filter enum
enum TaskFilter { all, pending, completed }

/// Task controller for managing actions
class TaskController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final CreateTaskUseCase createUseCase;
  final UpdateTaskUseCase updateUseCase;
  final DeleteTaskUseCase deleteUseCase;

  TaskController({
    required this.ref,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  }) : super(const AsyncValue.data(null));

  /// Create a new task
  Future<Task> createTask(String title, String description) async {
    state = const AsyncValue.loading();
    try {
      final newTask = Task(
        id: const Uuid().v4(),
        title: title,
        description: description,
        isCompleted: false,
        updatedAt: DateTime.now(),
      );
      final createdTask = await createUseCase.call(newTask);
      state = const AsyncValue.data(null);
      ref.invalidate(tasksProvider);
      return createdTask;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update an existing task
  Future<Task> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final updatedTask = await updateUseCase.call(
        task.copyWith(updatedAt: DateTime.now()),
      );
      state = const AsyncValue.data(null);
      ref.invalidate(tasksProvider);
      ref.invalidate(taskDetailProvider(task.id));
      return updatedTask;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      await deleteUseCase.call(id);
      state = const AsyncValue.data(null);
      ref.invalidate(tasksProvider);
      ref.invalidate(taskDetailProvider(id));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

