package com.Rahul.AshaSathi.DTO;

import lombok.Data;

/**
 * DTO representing a single lab test result extracted from OCR,
 * with severity populated by LabValidationService.
 */
@Data
public class LabResultDTO {
    private String testName;
    private String value;
    private String unit;
    private String referenceRange;

    // Populated by LabValidationService
    private String severity = "NORMAL";
}
