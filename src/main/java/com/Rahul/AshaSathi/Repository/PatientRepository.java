package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.Patient;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PatientRepository extends JpaRepository<Patient, Long> {
    List<Patient> findTop5ByUserIdOrderByUpdatedAtDesc(Long userId);
    List<Patient> findByUserId(Long userId);
    Optional<Patient> findByIdAndUserId(Long id, Long userId);
    Optional<Patient> findByClientTempIdAndUserId(String clientTempId, Long userId);
}
