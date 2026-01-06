package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.Entity.Task;
import com.Rahul.AshaSathi.Repository.TaskRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional
public class TaskService {

    private final TaskRepository taskRepo;

    public TaskService(TaskRepository taskRepo) {
        this.taskRepo = taskRepo;
    }

    // ✅ CREATE TASK
    public Task createTask(Task task) {
        task.setCreatedDate(LocalDate.now().toString()); // YYYY-MM-DD
        return taskRepo.save(task);
    }

    // ✅ GET TODAY TASKS
    @Transactional(readOnly = true)
    public List<Task> getTodayTasks(Long userId) {
        return taskRepo.findByUserIdAndCreatedDate(
                userId,
                LocalDate.now().toString()
        );
    }

    // ✅ DELETE TASK
    public void deleteTask(Long taskId, Long userId) {
        taskRepo.deleteByIdAndUserId(taskId, userId);
    }
}
