package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.Entity.Task;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Services.TaskService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @PostMapping
    public ResponseEntity<Task> createTask(
            @RequestBody Task task,
            @AuthenticationPrincipal User user) {

        task.setUser(user);
        return ResponseEntity.ok(taskService.createTask(task));
    }

    @GetMapping("/today")
    public ResponseEntity<List<Task>> getTodayTasks(
            @AuthenticationPrincipal User user) {

        return ResponseEntity.ok(
                taskService.getTodayTasks(user.getId())
        );
    }
}

