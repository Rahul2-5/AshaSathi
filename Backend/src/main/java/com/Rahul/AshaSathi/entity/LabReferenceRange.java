package com.Rahul.AshaSathi.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "lab_reference_ranges")
@Data
public class LabReferenceRange {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "test_name", nullable = false, unique = true)
    private String testName;

    @Column(name = "min_value")
    private Double minValue;

    @Column(name = "max_value")
    private Double maxValue;

    @Column(name = "critical_low")
    private Double criticalLow;

    @Column(name = "critical_high")
    private Double criticalHigh;

    @Column(name = "unit")
    private String unit;

    @Column(name = "gender")
    private String gender; // "ALL", "MALE", "FEMALE"
}
