package com.Rahul.AshaSathi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * ============================================
 * FAMILY PATIENT RESPONSE DTO
 * ============================================
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FamilyPatientResponseDTO {
    private Long id;
    private String patientName;
    private Integer age;
    private String dateOfBirth;
    private String gender;
    private String caste;
    private String address;
    private String phoneNumber;
    private Boolean isPregnant;
    private Integer monthsOfPregnancy;
    private String expectedDeliveryDate;
    private String photoPath;
    private Map<String, Boolean> diseases;
    private Boolean declinedHealthInfo;
    private String notes;
}
