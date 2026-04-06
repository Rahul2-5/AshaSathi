package com.Rahul.AshaSathi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.LocalDateTime;

/**
 * ============================================
 * FAMILY PATIENT ENTITY
 * ============================================
 * Represents individual patient records within a family
 */
@Entity
@Table(name = "family_patients")
@Data
@NoArgsConstructor
@AllArgsConstructor
@SuppressWarnings("unused") // Lombok @Data generates getters/setters
public class FamilyPatient {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String patientName;
    
    @Column(nullable = false)
    private Integer age;
    
    @Column(nullable = false)
    private String dateOfBirth;
    
    @Column(nullable = false)
    private String gender; // Female, Male, Other
    
    @Column
    private String caste;
    
    @Column(columnDefinition = "TEXT")
    private String address;
    
    @Column
    private String phoneNumber;
    
    // Pregnancy fields
    @Column
    private Boolean isPregnant = false;
    
    @Column
    private Integer monthsOfPregnancy;
    
    @Column
    private String expectedDeliveryDate;
    
    // Photo
    @Column
    private String photoPath;
    
    // Medical info - store as JSON
    @Column(columnDefinition = "TEXT")
    private String diseases; // JSON string of diseases map
    
    @Column
    private Boolean declinedHealthInfo = false;
    
    @Column(columnDefinition = "TEXT")
    private String notes;
    
    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();
    
    // Foreign key to family
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    @JsonIgnore
    private Family family;
    
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
