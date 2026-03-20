package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.Patient;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PatientRepository extends JpaRepository<Patient, Long> {
    List<Patient> findTop5ByOrderByUpdatedAtDesc();
}
