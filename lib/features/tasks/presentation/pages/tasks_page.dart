import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taller_flutter/features/tasks/domain/entities/task.dart';
import 'package:taller_flutter/features/tasks/presentation/providers/task_provider.dart';
import 'package:taller_flutter/features/tasks/presentation/widgets/task_list_item.dart';
import 'package:taller_flutter/features/tasks/presentation/widgets/create_task_dialog.dart';

/// Main tasks page displaying all tasks
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  @override
  void initState() {
    super.initState();
    // Initialize sync service here if needed
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final selectedFilter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Lista de Tareas'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(tasksProvider).whenData((_) {});
            },
            tooltip: 'Actualizar tareas',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterMenu(context, ref),
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todas',
                    selected: selectedFilter == TaskFilter.all,
                    onSelected: () {
                      ref.read(taskFilterProvider.notifier).state = TaskFilter.all;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pendientes',
                    selected: selectedFilter == TaskFilter.pending,
                    onSelected: () {
                      ref.read(taskFilterProvider.notifier).state = TaskFilter.pending;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completadas',
                    selected: selectedFilter == TaskFilter.completed,
                    onSelected: () {
                      ref.read(taskFilterProvider.notifier).state = TaskFilter.completed;
                    },
                  ),
                ],
              ),
            ),
          ),
          // Tasks list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedFilter == TaskFilter.all
                              ? 'No hay tareas'
                              : selectedFilter == TaskFilter.pending
                                  ? 'No hay tareas pendientes'
                                  : 'No hay tareas completadas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskListItem(
                      task: task,
                      onToggleComplete: () async {
                        try {
                          await ref
                              .read(taskControllerProvider.notifier)
                              .updateTask(
                                task.copyWith(isCompleted: !task.isCompleted),
                              );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      onEdit: () {
                        _showEditTaskDialog(context, ref, task);
                      },
                      onDelete: () async {
                        try {
                          await ref
                              .read(taskControllerProvider.notifier)
                              .deleteTask(task.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tarea eliminada')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
              loading: () {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(tasksProvider).whenData((_) {});
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateTaskDialog(context, ref);
        },
        tooltip: 'Nueva tarea',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        onTaskCreated: (title, description) async {
          try {
            await ref
                .read(taskControllerProvider.notifier)
                .createTask(title, description);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tarea creada')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        initialTitle: task.title,
        initialDescription: task.description,
        isEditMode: true,
        onTaskCreated: (title, description) async {
          try {
            await ref
                .read(taskControllerProvider.notifier)
                .updateTask(
                  task.copyWith(
                    title: title,
                    description: description,
                  ),
                );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tarea actualizada')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showFilterMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todas'),
              onTap: () {
                ref.read(taskFilterProvider.notifier).state = TaskFilter.all;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Pendientes'),
              onTap: () {
                ref.read(taskFilterProvider.notifier).state = TaskFilter.pending;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Completadas'),
              onTap: () {
                ref.read(taskFilterProvider.notifier).state = TaskFilter.completed;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
      ),
    );
  }
}

