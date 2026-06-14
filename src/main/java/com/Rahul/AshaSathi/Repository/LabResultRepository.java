package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.LabResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LabResultRepository extends JpaRepository<LabResult, Long> {
    List<LabResult> findByDocumentId(Long documentId);
    List<LabResult> findByDocumentIdAndSeverityNot(Long documentId, LabResult.Severity severity);
}
