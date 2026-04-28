package com.Rahul.AshaSathi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ============================================
 * FAMILY REGISTRATION RESPONSE DTO
 * ============================================
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FamilyRegistrationResponse {
    private Long familyId;
    private String message;
    private Integer patientCount;
    private String status; // "SUCCESS", "ERROR"
}
