package com.Rahul.AshaSathi.DTO;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FamilyRegistrationResponse {
    private Long familyId;
    private String message;
    private Integer patientCount;
    private String status;
}