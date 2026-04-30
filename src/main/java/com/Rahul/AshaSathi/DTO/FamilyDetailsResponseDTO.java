package com.Rahul.AshaSathi.DTO;

import java.util.List;

public class FamilyDetailsResponseDTO {
    private Long id;
    private String headOfFamily;
    private Integer numberOfMembers;
    private String familyAddress;
    private List<FamilyPatientResponseDTO> patients;

    public FamilyDetailsResponseDTO() {
    }

    public FamilyDetailsResponseDTO(Long id, String headOfFamily, Integer numberOfMembers, String familyAddress,
                                    List<FamilyPatientResponseDTO> patients) {
        this.id = id;
        this.headOfFamily = headOfFamily;
        this.numberOfMembers = numberOfMembers;
        this.familyAddress = familyAddress;
        this.patients = patients;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getHeadOfFamily() { return headOfFamily; }
    public void setHeadOfFamily(String headOfFamily) { this.headOfFamily = headOfFamily; }
    public Integer getNumberOfMembers() { return numberOfMembers; }
    public void setNumberOfMembers(Integer numberOfMembers) { this.numberOfMembers = numberOfMembers; }
    public String getFamilyAddress() { return familyAddress; }
    public void setFamilyAddress(String familyAddress) { this.familyAddress = familyAddress; }
    public List<FamilyPatientResponseDTO> getPatients() { return patients; }
    public void setPatients(List<FamilyPatientResponseDTO> patients) { this.patients = patients; }

    public static Builder builder() { return new Builder(); }

    public static final class Builder {
        private Long id;
        private String headOfFamily;
        private Integer numberOfMembers;
        private String familyAddress;
        private List<FamilyPatientResponseDTO> patients;

        public Builder id(Long id) { this.id = id; return this; }
        public Builder headOfFamily(String headOfFamily) { this.headOfFamily = headOfFamily; return this; }
        public Builder numberOfMembers(Integer numberOfMembers) { this.numberOfMembers = numberOfMembers; return this; }
        public Builder familyAddress(String familyAddress) { this.familyAddress = familyAddress; return this; }
        public Builder patients(List<FamilyPatientResponseDTO> patients) { this.patients = patients; return this; }
        public FamilyDetailsResponseDTO build() { return new FamilyDetailsResponseDTO(id, headOfFamily, numberOfMembers, familyAddress, patients); }
    }
}