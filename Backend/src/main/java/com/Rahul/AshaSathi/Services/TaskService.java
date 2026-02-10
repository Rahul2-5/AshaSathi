package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.DTO.TaskResponse;
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
        task.setCreatedDate(LocalDate.now().toString());
        return taskRepo.save(task);
    }

    // ✅ GET TODAY TASKS (RETURN DTO, NOT ENTITY)
    @Transactional(readOnly = true)
    public List<TaskResponse> getTodayTasks(Long userId) {

        return taskRepo.findByUserIdAndCreatedDate(
                        userId,
                        LocalDate.now().toString()
                ).stream()
                .map(task -> new TaskResponse(
                        task.getId(),
                        task.getTitle(),
                        task.getDescription(),
                        task.getStatus(),
                        task.getCreatedDate()
                ))
                .toList();
    }

    // ✅ DELETE TASK
    public void deleteTask(Long taskId, Long userId) {
        taskRepo.deleteByIdAndUserId(taskId, userId);
    }
}
