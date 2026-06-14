package com.Rahul.AshaSathi.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "drug_master")
@Data
public class DrugMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "drug_name", nullable = false, unique = true)
    private String drugName;

    @Column(name = "generic_name")
    private String genericName;

    @Column(name = "drug_class")
    private String drugClass;

    @Column(name = "active", nullable = false)
    private boolean active = true;
}
