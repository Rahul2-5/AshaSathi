package com.Rahul.AshaSathi.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "lab_results")
@Data
public class LabResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "document_id", nullable = false)
    private MedicalDocument document;

    @Column(name = "test_name", nullable = false)
    private String testName;

    @Column(name = "value")
    private String value;

    @Column(name = "unit")
    private String unit;

    @Enumerated(EnumType.STRING)
    @Column(name = "severity")
    private Severity severity = Severity.NORMAL;

    @Column(name = "reference_range")
    private String referenceRange;

    public enum Severity {
        NORMAL, LOW, HIGH, CRITICAL
    }
}
