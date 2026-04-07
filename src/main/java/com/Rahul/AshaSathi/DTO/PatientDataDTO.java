package com.Rahul.AshaSathi.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PatientDataDTO {
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