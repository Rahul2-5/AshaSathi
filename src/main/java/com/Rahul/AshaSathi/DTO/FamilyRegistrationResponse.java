package com.Rahul.AshaSathi.DTO;

public class FamilyRegistrationResponse {
    private Long familyId;
    private String message;
    private Integer patientCount;
    private String status;

    public FamilyRegistrationResponse() {
    }

    public FamilyRegistrationResponse(Long familyId, String message, Integer patientCount, String status) {
        this.familyId = familyId;
        this.message = message;
        this.patientCount = patientCount;
        this.status = status;
    }

    public Long getFamilyId() { return familyId; }
    public void setFamilyId(Long familyId) { this.familyId = familyId; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public Integer getPatientCount() { return patientCount; }
    public void setPatientCount(Integer patientCount) { this.patientCount = patientCount; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public static Builder builder() { return new Builder(); }

    public static final class Builder {
        private Long familyId;
        private String message;
        private Integer patientCount;
        private String status;

        public Builder familyId(Long familyId) { this.familyId = familyId; return this; }
        public Builder message(String message) { this.message = message; return this; }
        public Builder patientCount(Integer patientCount) { this.patientCount = patientCount; return this; }
        public Builder status(String status) { this.status = status; return this; }
        public FamilyRegistrationResponse build() { return new FamilyRegistrationResponse(familyId, message, patientCount, status); }
    }
}