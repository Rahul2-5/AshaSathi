package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.Entity.Task;
import com.Rahul.AshaSathi.Repository.TaskRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class TaskService {

    private final TaskRepository taskRepo;

    public TaskService(TaskRepository taskRepo) {
        this.taskRepo = taskRepo;
    }

    public Task createTask(Task task) {
        task.setCreatedDate(LocalDate.now());
        return taskRepo.save(task);
    }

    public List<Task> getTodayTasks(Long userId) {
        return taskRepo.findByUserIdAndCreatedDate(
                userId, LocalDate.now()
        );
    }
}
