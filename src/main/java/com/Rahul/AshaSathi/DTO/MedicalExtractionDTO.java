package com.Rahul.AshaSathi.DTO;

import lombok.Data;
import java.util.List;

/**
 * Internal DTO representing the structured medical data
 * extracted by Gemini 2.5 Flash and parsed by ResponseParser.
 */
@Data
public class MedicalExtractionDTO {
    private String diagnosis;
    private String followUpDate;
    private String notes;
    private List<MedicineDTO> medicines;
    private List<LabResultDTO> labTests;
}
