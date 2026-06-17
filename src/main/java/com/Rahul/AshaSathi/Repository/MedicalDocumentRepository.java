package com.Rahul.AshaSathi.Repository;

import com.Rahul.AshaSathi.Entity.MedicalDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicalDocumentRepository extends JpaRepository<MedicalDocument, Long> {
    List<MedicalDocument> findByPatientIdOrderByCreatedAtDesc(Long patientId);
    List<MedicalDocument> findByProcessingStatus(MedicalDocument.ProcessingStatus status);
    List<MedicalDocument> findAllByOrderByCreatedAtDesc();
}
