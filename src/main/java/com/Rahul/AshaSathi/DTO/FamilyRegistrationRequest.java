package com.Rahul.AshaSathi.DTO;

import java.util.List;

public class FamilyRegistrationRequest {
    private FamilyInfoDTO familyInfo;
    private List<PatientDataDTO> patients;

    public FamilyRegistrationRequest() {
    }

    public FamilyRegistrationRequest(FamilyInfoDTO familyInfo, List<PatientDataDTO> patients) {
        this.familyInfo = familyInfo;
        this.patients = patients;
    }

    public FamilyInfoDTO getFamilyInfo() {
        return familyInfo;
    }

    public void setFamilyInfo(FamilyInfoDTO familyInfo) {
        this.familyInfo = familyInfo;
    }

    public List<PatientDataDTO> getPatients() {
        return patients;
    }

    public void setPatients(List<PatientDataDTO> patients) {
        this.patients = patients;
    }
}