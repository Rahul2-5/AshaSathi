package com.Rahul.AshaSathi.Entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Represents a single lab test result extracted from a medical document.
 * Severity is classified by LabValidationService.
 */
@Entity
@Table(name = "lab_result", indexes = {
    @Index(name = "idx_lab_result_document", columnList = "document_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LabResult {

    public enum Severity { NORMAL, LOW, HIGH, CRITICAL }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_id", nullable = false)
    private MedicalDocument document;

    @Column(name = "test_name", nullable = false, length = 300)
    private String testName;

    @Column(name = "value", length = 100)
    private String value;

    @Column(name = "unit", length = 50)
    private String unit;

    @Column(name = "reference_range", length = 200)
    private String referenceRange;

    @Enumerated(EnumType.STRING)
    @Column(name = "severity", nullable = false, length = 20)
    @Builder.Default
    private Severity severity = Severity.NORMAL;
}
