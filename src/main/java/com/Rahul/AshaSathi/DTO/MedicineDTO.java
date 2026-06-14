package com.Rahul.AshaSathi.DTO;

import lombok.Data;

/**
 * DTO representing a single medicine extracted from OCR,
 * with drug validation fields populated by DrugValidationService.
 */
@Data
public class MedicineDTO {
    private String medicineName;
    private String dosage;
    private String frequency;
    private String duration;

    // Populated by DrugValidationService
    private boolean verified;
    private String matchedDrugName;
    private Integer matchScore;
}
