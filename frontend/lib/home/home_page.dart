import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/login_cubit.dart';
import '../task/task_cubit.dart';
import '../task/add_task_page.dart';
import '../utils/app_colors.dart';
import 'widgets/task_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();

    // 🔥 Load today's tasks on dashboard open
    final token = context.read<LoginCubit>().state.token!;
    context.read<TaskCubit>().loadTasks(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // 🧭 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "ASHA Dashboard",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.black),
          SizedBox(width: 12),
          CircleAvatar(radius: 16),
          SizedBox(width: 12),
        ],
      ),

      // 📋 BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 👋 WELCOME
            const Text(
              "Welcome, ASHA Worker!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Your daily overview",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // 📌 DAILY TASKS HEADER
           Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Daily Tasks",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskPage()),
        );

        if (result == true) {
          final token = context.read<LoginCubit>().state.token!;
          context.read<TaskCubit>().loadTasks(token);
        }
      },
    ),
  ],
),

            const SizedBox(height: 12),

            // 📄 TASK LIST
            Expanded(
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  print("UI received tasks: ${state.tasks.length}");
                  if (state.loading && state.tasks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.tasks.isEmpty) {
                    return const Center(
                      child: Text("No tasks for today"),
                    );
                  }

                  return ListView.separated(
                    itemCount: state.tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = state.tasks[index];
                      return TaskCard(task: task);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
