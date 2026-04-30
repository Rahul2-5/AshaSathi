package com.Rahul.AshaSathi.DTO;

import java.util.Map;

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

    public FamilyPatientResponseDTO() {
    }

    public FamilyPatientResponseDTO(Long id, String patientName, Integer age, String dateOfBirth, String gender,
                                    String caste, String address, String phoneNumber, Boolean isPregnant,
                                    Integer monthsOfPregnancy, String expectedDeliveryDate, String photoPath,
                                    Map<String, Boolean> diseases, Boolean declinedHealthInfo, String notes) {
        this.id = id;
        this.patientName = patientName;
        this.age = age;
        this.dateOfBirth = dateOfBirth;
        this.gender = gender;
        this.caste = caste;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.isPregnant = isPregnant;
        this.monthsOfPregnancy = monthsOfPregnancy;
        this.expectedDeliveryDate = expectedDeliveryDate;
        this.photoPath = photoPath;
        this.diseases = diseases;
        this.declinedHealthInfo = declinedHealthInfo;
        this.notes = notes;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }
    public Integer getAge() { return age; }
    public void setAge(Integer age) { this.age = age; }
    public String getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(String dateOfBirth) { this.dateOfBirth = dateOfBirth; }
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public String getCaste() { return caste; }
    public void setCaste(String caste) { this.caste = caste; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public Boolean getIsPregnant() { return isPregnant; }
    public void setIsPregnant(Boolean isPregnant) { this.isPregnant = isPregnant; }
    public Integer getMonthsOfPregnancy() { return monthsOfPregnancy; }
    public void setMonthsOfPregnancy(Integer monthsOfPregnancy) { this.monthsOfPregnancy = monthsOfPregnancy; }
    public String getExpectedDeliveryDate() { return expectedDeliveryDate; }
    public void setExpectedDeliveryDate(String expectedDeliveryDate) { this.expectedDeliveryDate = expectedDeliveryDate; }
    public String getPhotoPath() { return photoPath; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }
    public Map<String, Boolean> getDiseases() { return diseases; }
    public void setDiseases(Map<String, Boolean> diseases) { this.diseases = diseases; }
    public Boolean getDeclinedHealthInfo() { return declinedHealthInfo; }
    public void setDeclinedHealthInfo(Boolean declinedHealthInfo) { this.declinedHealthInfo = declinedHealthInfo; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public static Builder builder() { return new Builder(); }

    public static final class Builder {
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

        public Builder id(Long id) { this.id = id; return this; }
        public Builder patientName(String patientName) { this.patientName = patientName; return this; }
        public Builder age(Integer age) { this.age = age; return this; }
        public Builder dateOfBirth(String dateOfBirth) { this.dateOfBirth = dateOfBirth; return this; }
        public Builder gender(String gender) { this.gender = gender; return this; }
        public Builder caste(String caste) { this.caste = caste; return this; }
        public Builder address(String address) { this.address = address; return this; }
        public Builder phoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; return this; }
        public Builder isPregnant(Boolean isPregnant) { this.isPregnant = isPregnant; return this; }
        public Builder monthsOfPregnancy(Integer monthsOfPregnancy) { this.monthsOfPregnancy = monthsOfPregnancy; return this; }
        public Builder expectedDeliveryDate(String expectedDeliveryDate) { this.expectedDeliveryDate = expectedDeliveryDate; return this; }
        public Builder photoPath(String photoPath) { this.photoPath = photoPath; return this; }
        public Builder diseases(Map<String, Boolean> diseases) { this.diseases = diseases; return this; }
        public Builder declinedHealthInfo(Boolean declinedHealthInfo) { this.declinedHealthInfo = declinedHealthInfo; return this; }
        public Builder notes(String notes) { this.notes = notes; return this; }
        public FamilyPatientResponseDTO build() {
            return new FamilyPatientResponseDTO(id, patientName, age, dateOfBirth, gender, caste, address, phoneNumber, isPregnant, monthsOfPregnancy, expectedDeliveryDate, photoPath, diseases, declinedHealthInfo, notes);
        }
    }
}