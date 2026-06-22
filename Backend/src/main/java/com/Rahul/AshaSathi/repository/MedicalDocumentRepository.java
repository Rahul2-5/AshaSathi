package com.Rahul.AshaSathi.repository;

import com.Rahul.AshaSathi.entity.MedicalDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface MedicalDocumentRepository extends JpaRepository<MedicalDocument, Long> {
    List<MedicalDocument> findByPatientId(Long patientId);
    List<MedicalDocument> findByProcessingStatus(MedicalDocument.ProcessingStatus status);
    List<MedicalDocument> findAllByOrderByCreatedAtDesc();

    @Modifying
    @Transactional
    @Query("UPDATE MedicalDocument d SET d.aiSummary = :aiSummary, d.ashaActions = :ashaActions WHERE d.id = :id")
    void updateSummary(@Param("id") Long id,
                       @Param("aiSummary") String aiSummary,
                       @Param("ashaActions") String ashaActions);
}
