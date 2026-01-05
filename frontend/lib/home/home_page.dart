import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/login_page.dart';
import '../services/auth_service.dart';
import '../task/task_cubit.dart';
import '../task/add_task_page.dart';

class HomePage extends StatelessWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    context.read<TaskCubit>().loadTasks(token);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ASHA Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1️⃣ Logout (Google / normal)
              await AuthService().logout();

              // 2️⃣ Clear navigation stack & go to login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginView(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskPage(token: token),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          if (state.tasks.isEmpty) {
            return const Center(
              child: Text("No tasks available"),
            );
          }

          return ListView(
            children: state.tasks.map((task) {
              return ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Chip(
                  label: Text(task.status.name.toUpperCase()),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
