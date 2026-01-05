import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/task_service.dart';
import 'task_model.dart';

class TaskState {
  final bool loading;
  final List<TaskModel> tasks;
  final String? error;

  TaskState({
    this.loading = false,
    this.tasks = const [],
    this.error,
  });
}

class TaskCubit extends Cubit<TaskState> {
  final TaskService taskService;

  TaskCubit(this.taskService) : super(TaskState());

  Future<void> loadTasks(String token) async {
    emit(TaskState(loading: true));
    try {
      final tasks = await taskService.fetchTodayTasks(token);
      emit(TaskState(tasks: tasks));
    } catch (e) {
      emit(TaskState(error: e.toString()));
    }
  }

  Future<void> addTask(TaskModel task, String token) async {
    await taskService.addTask(task, token);
    await loadTasks(token);
  }
}
