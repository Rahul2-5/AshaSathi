package com.Rahul.AshaSathi.Entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Represents a single medicine extracted from a medical document.
 * Includes drug validation results from DrugValidationService.
 */
@Entity
@Table(name = "medicine", indexes = {
    @Index(name = "idx_medicine_document", columnList = "document_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Medicine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_id", nullable = false)
    private MedicalDocument document;

    @Column(name = "medicine_name", nullable = false, length = 300)
    private String medicineName;

    @Column(name = "dosage", length = 100)
    private String dosage;

    @Column(name = "frequency", length = 100)
    private String frequency;

    @Column(name = "duration", length = 100)
    private String duration;

    /** True if this medicine was found (exact or fuzzy) in drug_master. */
    @Column(name = "verified", nullable = false)
    @Builder.Default
    private boolean verified = false;

    /** The matched drug name from drug_master (may differ from OCR text). */
    @Column(name = "matched_drug_name", length = 300)
    private String matchedDrugName;

    /** Fuzzy match score 0-100. 100 = exact match. */
    @Column(name = "match_score")
    private Integer matchScore;
}
