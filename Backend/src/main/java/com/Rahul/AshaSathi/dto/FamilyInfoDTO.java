package com.Rahul.AshaSathi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ============================================
 * FAMILY INFO DTO
 * ============================================
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FamilyInfoDTO {
    private String headOfFamily;
    private Integer numberOfMembers;
    private String familyAddress;
}
