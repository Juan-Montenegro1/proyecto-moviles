import 'package:uuid/uuid.dart';
import 'package:taller_flutter/features/tasks/domain/entities/task.dart';
import 'package:taller_flutter/features/tasks/domain/repositories/task_repository.dart';
import 'package:taller_flutter/features/tasks/data/models/task_model.dart';
import 'package:taller_flutter/features/tasks/data/models/queue_operation.dart';
import 'package:taller_flutter/features/tasks/data/local/database.dart';
import 'package:taller_flutter/features/tasks/data/remote/tasks_api.dart';
import 'package:taller_flutter/core/errors/exceptions.dart';

/// Implementation of TaskRepository with offline-first strategy
class TaskRepositoryImpl implements TaskRepository {
  final LocalDatabase localDatabase;
  final TasksRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({
    required this.localDatabase,
    required this.remoteDataSource,
  });

  @override
  Future<List<Task>> getTasks() async {
    try {
      // First, try to get from local database
      final localTasks = await localDatabase.getAllTasks();
      return localTasks;
    } catch (e) {
      throw DatabaseException(message: 'Failed to get tasks from local database');
    }
  }

  @override
  Future<List<Task>> fetchTasksFromRemote() async {
    try {
      final remoteTasks = await remoteDataSource.getTasks();
      
      // Save to local database
      for (final task in remoteTasks) {
        await localDatabase.insertTask(task);
      }
      
      return remoteTasks;
    } catch (e) {
      throw NetworkException(message: 'Failed to fetch tasks from remote: $e');
    }
  }

  @override
  Future<Task> getTaskById(String id) async {
    try {
      final localTask = await localDatabase.getTaskById(id);
      if (localTask != null) {
        return localTask;
      }
      throw DatabaseException(message: 'Task not found');
    } catch (e) {
      throw DatabaseException(message: 'Failed to get task: $e');
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      
      // Save to local database first
      await localDatabase.insertTask(taskModel);
      
      // Queue the operation for later sync
      final operation = QueueOperation(
        id: const Uuid().v4(),
        entity: 'tasks',
        entityId: task.id,
        operation: QueueOperationType.create,
        payload: taskModel.toJson(),
        createdAt: DateTime.now(),
      );
      
      await localDatabase.insertQueueOperation(operation);
      
      return taskModel;
    } catch (e) {
      throw DatabaseException(message: 'Failed to create task: $e');
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      
      // Update local database
      await localDatabase.updateTask(taskModel);
      
      // Queue the operation for later sync
      final operation = QueueOperation(
        id: const Uuid().v4(),
        entity: 'tasks',
        entityId: task.id,
        operation: QueueOperationType.update,
        payload: taskModel.toJson(),
        createdAt: DateTime.now(),
      );
      
      await localDatabase.insertQueueOperation(operation);
      
      return taskModel;
    } catch (e) {
      throw DatabaseException(message: 'Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      // Soft delete in local database
      await localDatabase.deleteTask(id);
      
      // Queue the operation for later sync
      final operation = QueueOperation(
        id: const Uuid().v4(),
        entity: 'tasks',
        entityId: id,
        operation: QueueOperationType.delete,
        payload: {'id': id},
        createdAt: DateTime.now(),
      );
      
      await localDatabase.insertQueueOperation(operation);
    } catch (e) {
      throw DatabaseException(message: 'Failed to delete task: $e');
    }
  }

  @override
  Future<List<Task>> getFilteredTasks({bool? completed}) async {
    try {
      final allTasks = await getTasks();
      
      if (completed == null) {
        return allTasks;
      }
      
      return allTasks.where((task) => task.isCompleted == completed).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to filter tasks: $e');
    }
  }

  /// Sync pending operations with remote server
  Future<void> syncPendingOperations() async {
    try {
      final pendingOps = await localDatabase.getOperationsToSync();
      
      for (final operation in pendingOps) {
        try {
          await localDatabase.incrementAttemptCount(operation.id);
          
          TaskModel? syncedTask;
          
          switch (operation.operation) {
            case QueueOperationType.create:
              final taskModel = TaskModel.fromJson(operation.payload);
              syncedTask = await remoteDataSource.createTask(taskModel);
              break;
            case QueueOperationType.update:
              final taskModel = TaskModel.fromJson(operation.payload);
              syncedTask = await remoteDataSource.updateTask(
                operation.entityId,
                taskModel,
              );
              break;
            case QueueOperationType.delete:
              await remoteDataSource.deleteTask(operation.entityId);
              break;
          }
          
          // Update local data with synced data if it's create/update
          if (syncedTask != null) {
            await localDatabase.insertTask(syncedTask);
          }
          
          // Remove from queue after successful sync
          await localDatabase.deleteQueueOperation(operation.id);
        } catch (e) {
          // Store error and continue with next operation
          await localDatabase.setOperationError(operation.id, e.toString());
        }
      }
    } catch (e) {
      // Log sync error but don't throw - user can retry
    }
  }

  /// Check for conflicts using Last-Write-Wins strategy
  Future<Task> resolveConflict(Task local, Task remote) async {
    // Compare updatedAt timestamps
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      // Remote is newer
      return remote;
    }
    // Local is newer or equal
    return local;
  }
}

