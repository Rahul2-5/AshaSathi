package com.Rahul.AshaSathi.repository;

import com.Rahul.AshaSathi.entity.LabReferenceRange;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LabReferenceRangeRepository extends JpaRepository<LabReferenceRange, Long> {
    Optional<LabReferenceRange> findByTestNameIgnoreCase(String testName);
}
