import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:taller_flutter/features/tasks/data/models/task_model.dart';
import 'package:taller_flutter/core/errors/exceptions.dart';

/// Remote data source for tasks API
class TasksRemoteDataSource {
  final http.Client httpClient;
  final String baseUrl;

  TasksRemoteDataSource({
    required this.httpClient,
    required this.baseUrl,
  });

  /// Get all tasks from API
  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/tasks'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw NetworkException(message: 'Unauthorized');
      } else if (response.statusCode >= 500) {
        throw NetworkException(message: 'Server error: ${response.statusCode}');
      } else {
        throw NetworkException(message: 'Failed to fetch tasks');
      }
    } on http.ClientException {
      throw NetworkException(message: 'Network error');
    }
  }

  /// Get single task by ID
  Future<TaskModel> getTaskById(String id) async {
    try {
      final response = await httpClient.get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return TaskModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NetworkException(message: 'Task not found');
      } else if (response.statusCode >= 500) {
        throw NetworkException(message: 'Server error: ${response.statusCode}');
      } else {
        throw NetworkException(message: 'Failed to fetch task');
      }
    } on http.ClientException {
      throw NetworkException(message: 'Network error');
    }
  }

  /// Create a new task
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final body = jsonEncode(task.toJson());
      final response = await httpClient.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TaskModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw NetworkException(message: 'Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw NetworkException(message: 'Server error: ${response.statusCode}');
      } else {
        throw NetworkException(message: 'Failed to create task');
      }
    } on http.ClientException {
      throw NetworkException(message: 'Network error');
    }
  }

  /// Update a task
  Future<TaskModel> updateTask(String id, TaskModel task) async {
    try {
      final body = jsonEncode(task.toJson());
      final response = await httpClient.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TaskModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NetworkException(message: 'Task not found');
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw NetworkException(message: 'Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw NetworkException(message: 'Server error: ${response.statusCode}');
      } else {
        throw NetworkException(message: 'Failed to update task');
      }
    } on http.ClientException {
      throw NetworkException(message: 'Network error');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    try {
      final response = await httpClient.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw NetworkException(message: 'Task not found');
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw NetworkException(message: 'Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw NetworkException(message: 'Server error: ${response.statusCode}');
      } else {
        throw NetworkException(message: 'Failed to delete task');
      }
    } on http.ClientException {
      throw NetworkException(message: 'Network error');
    }
  }

  /// Get common headers with Idempotency-Key
  Map<String, String> _getHeaders({String? idempotencyKey}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Idempotency-Key': idempotencyKey ?? const Uuid().v4(),
    };
  }
}

