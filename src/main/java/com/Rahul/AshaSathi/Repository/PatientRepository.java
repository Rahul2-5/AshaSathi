package com.Rahul.AshaSathi.Repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.Rahul.AshaSathi.Entity.Patient;

public interface PatientRepository extends JpaRepository<Patient, Long> {
    List<Patient> findTop5ByOrderByUpdatedAtDesc();

    void deleteByClientTempIdStartingWith(String prefix);
}
