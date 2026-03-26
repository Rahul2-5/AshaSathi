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

    //  CREATE TASK
    public Task createTask(Task task) {
        task.setCreatedDate(LocalDate.now().toString());
        return taskRepo.save(task);
    }

    //  GET TODAY TASKS (RETURN DTO, NOT ENTITY)
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

    //  UPDATE TASK
    public Task updateTask(Long taskId, Task updatedTask, Long userId) {
        Task task = taskRepo.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        // Verify the task belongs to the user
        if (!task.getUser().getId().equals(userId)) {
            throw new RuntimeException("Unauthorized: Task does not belong to this user");
        }

        // Update fields
        if (updatedTask.getTitle() != null) {
            task.setTitle(updatedTask.getTitle());
        }
        if (updatedTask.getDescription() != null) {
            task.setDescription(updatedTask.getDescription());
        }
        if (updatedTask.getStatus() != null) {
            task.setStatus(updatedTask.getStatus());
        }

        return taskRepo.save(task);
    }

    //  DELETE TASK
    public void deleteTask(Long taskId, Long userId) {
        taskRepo.deleteByIdAndUserId(taskId, userId);
    }
}
