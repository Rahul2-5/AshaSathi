import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/task/task_model.dart';
import 'package:frontend/services/task_service.dart';

// ==================== TASK STATE ====================
class TaskListState {
  final bool loading;
  final List<TaskModel> tasks;
  final String? error;

  TaskListState({
    this.loading = false,
    this.tasks = const [],
    this.error,
  });

  TaskListState copyWith({
    bool? loading,
    List<TaskModel>? tasks,
    String? error,
  }) {
    return TaskListState(
      loading: loading ?? this.loading,
      tasks: tasks ?? this.tasks,
      error: error ?? this.error,
    );
  }
}

// ==================== TASK SERVICE PROVIDER ====================
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

// ==================== TASK LIST NOTIFIER ====================
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskService taskService;

  TaskListNotifier(this.taskService) : super(TaskListState());

  // 📥 Load today's tasks
  Future<void> loadTasks(String token) async {
    state = state.copyWith(loading: true);

    try {
      final tasks = await taskService.fetchTodayTasks(token);
      state = TaskListState(loading: false, tasks: tasks);
    } catch (e) {
      // 🔴 DO NOT wipe tasks on offline error
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ➕ Add a new task — optimistic update
  Future<void> addTask(TaskModel task, String token) async {
    // ⚡ Instantly show the new task in the list (optimistic)
    state = state.copyWith(tasks: [task, ...state.tasks]);
    try {
      await taskService.addTask(task, token);
      // Silently sync from backend to get the real server ID
      await loadTasks(token);
    } catch (e) {
      // Revert optimistic update on failure
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.uuid != task.uuid).toList(),
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ❌ Delete a task by ID — optimistic update
  Future<void> deleteTask(int taskId, String token) async {
    final previousTasks = state.tasks;
    // ⚡ Remove instantly from UI
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
    );
    try {
      await taskService.deleteTask(taskId, "", token);
      // Silent background sync
      loadTasks(token);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(tasks: previousTasks, error: e.toString());
      rethrow;
    }
  }

  // 🔄 Update a task — optimistic update
  Future<void> updateTask(TaskModel task, String token) async {
    final previousTasks = state.tasks;
    // ⚡ Instantly reflect changes in the list
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.uuid == task.uuid ? task : t).toList(),
    );
    try {
      await taskService.updateTask(task, token);
      // Silent background sync
      loadTasks(token);
    } catch (e) {
      // Revert on failure
      state = state.copyWith(tasks: previousTasks, error: e.toString());
      rethrow;
    }
  }

  // 🗑️ Delete task with UUID — optimistic update
  Future<bool> deleteTaskWithUuid(int taskId, String uuid, String token) async {
    final previousTasks = state.tasks;
    // ⚡ Remove instantly from UI
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.uuid != uuid && t.id != taskId).toList(),
    );
    try {
      final deleted = await taskService.deleteTask(taskId, uuid, token);
      // Silent background sync
      loadTasks(token);
      return deleted;
    } catch (e) {
      // Revert on failure
      state = state.copyWith(tasks: previousTasks, error: e.toString());
      rethrow;
    }
  }

  // 🔄 Refresh tasks
  Future<void> refreshTasks(String token) async {
    await loadTasks(token);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ==================== TASK LIST PROVIDER ====================
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TaskListNotifier(taskService);
});

// ==================== COMPLETED TASKS PROVIDER ====================
final completedTasksProvider = Provider<List<TaskModel>>((ref) {
  final taskState = ref.watch(taskListProvider);
  return taskState.tasks.where((task) => task.isCompleted).toList();
});

// ==================== PENDING TASKS PROVIDER ====================
final pendingTasksProvider = Provider<List<TaskModel>>((ref) {
  final taskState = ref.watch(taskListProvider);
  return taskState.tasks.where((task) => !task.isCompleted).toList();
});

// ==================== TASK COUNT PROVIDER ====================
final taskCountProvider = Provider<int>((ref) {
  final taskState = ref.watch(taskListProvider);
  return taskState.tasks.length;
});

// ==================== TASK SEARCH PROVIDER ====================
final taskSearchProvider = StateNotifierProvider<TaskSearchNotifier, String>((ref) {
  return TaskSearchNotifier();
});

class TaskSearchNotifier extends StateNotifier<String> {
  TaskSearchNotifier() : super('');

  void updateSearch(String query) {
    state = query;
  }

  void clearSearch() {
    state = '';
  }
}

// ==================== FILTERED TASKS PROVIDER ====================
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final taskState = ref.watch(taskListProvider);
  final searchQuery = ref.watch(taskSearchProvider);

  if (searchQuery.isEmpty) {
    return taskState.tasks;
  }

  return taskState.tasks
      .where((task) =>
          task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();
});

// ==================== TASK FILTER PROVIDER ====================
class TaskFilter {
  final String? status; // 'all', 'pending', 'completed'
  final String? priority; // 'low', 'medium', 'high'
  final String sortBy; // 'dueDate', 'priority', 'newest'

  TaskFilter({
    this.status,
    this.priority,
    this.sortBy = 'dueDate',
  });

  TaskFilter copyWith({
    String? status,
    String? priority,
    String? sortBy,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final taskFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilter>((ref) {
  return TaskFilterNotifier();
});

class TaskFilterNotifier extends StateNotifier<TaskFilter> {
  TaskFilterNotifier() : super(TaskFilter());

  void updateStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void updatePriority(String? priority) {
    state = state.copyWith(priority: priority);
  }

  void updateSort(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void resetFilter() {
    state = TaskFilter();
  }
}

// ==================== SEARCHED, FILTERED & SORTED TASKS PROVIDER ====================
final searchedFilteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final taskState = ref.watch(taskListProvider);
  final searchQuery = ref.watch(taskSearchProvider);
  final filter = ref.watch(taskFilterProvider);

  var filtered = taskState.tasks;

  // Apply search
  if (searchQuery.isNotEmpty) {
    filtered = filtered
        .where((task) =>
            task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  // Apply status filter
  if (filter.status != null && filter.status != 'all') {
    if (filter.status == 'pending') {
      filtered = filtered.where((task) => !task.isCompleted).toList();
    } else if (filter.status == 'completed') {
      filtered = filtered.where((task) => task.isCompleted).toList();
    }
  }

  // Apply sorting based on available fields
  switch (filter.sortBy) {
    case 'priority':
      // Priority sorting not yet implemented - tasks don't have priority field
      // Sort by status instead
      filtered.sort((a, b) => a.status.index.compareTo(b.status.index));
      break;
    case 'dueDate':
      // Due date sorting not yet implemented - tasks don't have dueDate field
      // Keep original order
      break;
    case 'newest':
    default:
      // Keep original order (most recent first by default)
      break;
  }

  return filtered;
});
