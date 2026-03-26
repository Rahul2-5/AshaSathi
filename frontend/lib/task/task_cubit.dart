import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/task_service.dart';
import 'task_model.dart';

class TaskState extends Equatable {
  final bool loading;
  final List<TaskModel> tasks;
  final String? error;

  const TaskState({
    this.loading = false,
    this.tasks = const [],
    this.error,
  });

  @override
  List<Object?> get props => [loading, tasks, error];
}

class TaskCubit extends Cubit<TaskState> {
  final TaskService taskService;

  TaskCubit(this.taskService) : super(const TaskState());

  Future<void> loadTasks(String token) async {
  emit(TaskState(loading: true, tasks: state.tasks));
  try {
    final tasks = await taskService.fetchTodayTasks(token);
    emit(TaskState(tasks: tasks));
  } catch (_) {
    // 🔴 DO NOT wipe tasks on offline error
    emit(TaskState(tasks: state.tasks));
  }
}


  Future<void> addTask(TaskModel task, String token) async {
    try {
      await taskService.addTask(task, token);

      // 🔑 Only reload from backend if online
      await loadTasks(token);
    } catch (e) {
      emit(TaskState(error: e.toString(), tasks: state.tasks));
    }
  }

  Future<void> deleteTask(int taskId, String token) async {
    try {
      await taskService.deleteTask(taskId, "", token);
      await loadTasks(token);
    } catch (e) {
      emit(TaskState(error: e.toString(), tasks: state.tasks));
    }
  }

  Future<void> updateTask(TaskModel task, String token) async {
    try {
      await taskService.updateTask(task, token);
      await loadTasks(token);
    } catch (e) {
      emit(TaskState(error: e.toString(), tasks: state.tasks));
    }
  }

  Future<bool> deleteTaskWithUuid(int taskId, String uuid, String token) async {
    try {
      final deleted = await taskService.deleteTask(taskId, uuid, token);
      await loadTasks(token);
      return deleted;
    } catch (e) {
      emit(TaskState(error: e.toString(), tasks: state.tasks));
      rethrow;
    }
  }
}
