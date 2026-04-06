package com.Rahul.AshaSathi.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

/**
 * ============================================
 * FAMILY ENTITY
 * ============================================
 * Represents a family unit
 */
@Entity
@Table(name = "families")
@Data
@NoArgsConstructor
@AllArgsConstructor
@SuppressWarnings("unused") // Lombok @Data generates getters/setters
public class Family {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String headOfFamily;
    
    @Column(nullable = false)
    private Integer numberOfMembers;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String familyAddress;
    
    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();
    
    // Relationships
    @OneToMany(mappedBy = "family", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<FamilyPatient> patients;
    
    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
