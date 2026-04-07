package com.Rahul.AshaSathi.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FamilyRegistrationRequest {
    private FamilyInfoDTO familyInfo;
    private List<PatientDataDTO> patients;
}