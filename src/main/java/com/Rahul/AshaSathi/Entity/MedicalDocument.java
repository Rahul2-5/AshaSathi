package com.Rahul.AshaSathi.Entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Represents a processed medical document (prescription, lab report, discharge summary).
 * Central entity for the Medical Vision Agent pipeline.
 */
@Entity
@Table(name = "medical_document", indexes = {
    @Index(name = "idx_medical_doc_patient", columnList = "patient_id"),
    @Index(name = "idx_medical_doc_status",  columnList = "processing_status")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MedicalDocument {

    public enum ProcessingStatus { PENDING, PROCESSING, COMPLETED, FAILED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "patient_id")
    private Long patientId;

    @Column(name = "image_path", length = 512)
    private String imagePath;

    @Column(name = "raw_text", columnDefinition = "TEXT")
    private String rawText;

    @Column(name = "diagnosis", length = 1000)
    private String diagnosis;

    @Column(name = "follow_up_date")
    private LocalDate followUpDate;

    @Column(name = "ai_summary", columnDefinition = "TEXT")
    private String aiSummary;

    @Enumerated(EnumType.STRING)
    @Column(name = "processing_status", nullable = false, length = 20)
    @Builder.Default
    private ProcessingStatus processingStatus = ProcessingStatus.PENDING;

    @Column(name = "confidence_score")
    private Double confidenceScore;

    @Column(name = "error_message", length = 500)
    private String errorMessage;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // ── Relationships ─────────────────────────────────────────────────────────

    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<Medicine> medicines = new ArrayList<>();

    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<LabResult> labResults = new ArrayList<>();

    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<OcrLine> ocrLines = new ArrayList<>();
}
