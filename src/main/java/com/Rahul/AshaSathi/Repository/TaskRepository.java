package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByUserIdAndCreatedDate(Long userId, String createdDate);

    void deleteByIdAndUserId(Long id, Long userId);
}
