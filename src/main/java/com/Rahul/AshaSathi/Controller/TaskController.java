package com.Rahul.AshaSathi.Controller;

import com.Rahul.AshaSathi.Entity.Task;
import com.Rahul.AshaSathi.Entity.User;
import com.Rahul.AshaSathi.Repository.UserRepository;
import com.Rahul.AshaSathi.Services.TaskService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final TaskService taskService;
    private final UserRepository userRepository;

    public TaskController(TaskService taskService, UserRepository userRepository) {
        this.taskService = taskService;
        this.userRepository = userRepository;
    }

    // ✅ CREATE TASK
    @PostMapping
    public ResponseEntity<Task> createTask(
            @RequestBody Task task,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String email = userDetails.getUsername();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        task.setUser(user);
        return ResponseEntity.ok(taskService.createTask(task));
    }

    // ✅ GET TODAY TASKS
    @GetMapping("/today")
    public ResponseEntity<List<Task>> getTodayTasks(
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String email = userDetails.getUsername();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(
                taskService.getTodayTasks(user.getId())
        );
    }

    // 🔥 DELETE TASK
    @DeleteMapping("/{taskId}")
    public ResponseEntity<Void> deleteTask(
            @PathVariable Long taskId,
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        String email = userDetails.getUsername();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        taskService.deleteTask(taskId, user.getId());
        return ResponseEntity.noContent().build();
    }
}
