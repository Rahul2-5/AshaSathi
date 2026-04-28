package com.Rahul.AshaSathi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * ============================================
 * FAMILY DETAILS RESPONSE DTO
 * ============================================
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FamilyDetailsResponseDTO {
    private Long id;
    private String headOfFamily;
    private Integer numberOfMembers;
    private String familyAddress;
    private List<FamilyPatientResponseDTO> patients;
}
