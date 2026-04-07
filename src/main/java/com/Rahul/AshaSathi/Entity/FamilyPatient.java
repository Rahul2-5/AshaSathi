package com.Rahul.AshaSathi.Entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "family_patients")
@Data
@NoArgsConstructor
@AllArgsConstructor
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
    private String gender;

    @Column
    private String caste;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column
    private String phoneNumber;

    @Column
    private Boolean isPregnant = false;

    @Column
    private Integer monthsOfPregnancy;

    @Column
    private String expectedDeliveryDate;

    @Column
    private String photoPath;

    @Column(columnDefinition = "TEXT")
    private String diseases;

    @Column
    private Boolean declinedHealthInfo = false;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "family_id", nullable = false)
    @JsonIgnore
    private Family family;

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}