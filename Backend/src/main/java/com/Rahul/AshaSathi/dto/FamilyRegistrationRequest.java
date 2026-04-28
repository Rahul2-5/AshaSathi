package com.Rahul.AshaSathi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

/**
 * ============================================
 * FAMILY REGISTRATION REQUEST DTO
 * ============================================
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FamilyRegistrationRequest {
    private FamilyInfoDTO familyInfo;
    private List<PatientDataDTO> patients;
}
