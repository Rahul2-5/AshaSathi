package com.Rahul.AshaSathi.repository;

import com.Rahul.AshaSathi.entity.MedicalDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicalDocumentRepository extends JpaRepository<MedicalDocument, Long> {
    List<MedicalDocument> findByPatientId(Long patientId);
    List<MedicalDocument> findByProcessingStatus(MedicalDocument.ProcessingStatus status);
    List<MedicalDocument> findAllByOrderByCreatedAtDesc();
}
