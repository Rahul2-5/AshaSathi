package com.Rahul.AshaSathi.DTO;

public class FamilyInfoDTO {
    private String headOfFamily;
    private Integer numberOfMembers;
    private String familyAddress;

    public FamilyInfoDTO() {
    }

    public FamilyInfoDTO(String headOfFamily, Integer numberOfMembers, String familyAddress) {
        this.headOfFamily = headOfFamily;
        this.numberOfMembers = numberOfMembers;
        this.familyAddress = familyAddress;
    }

    public String getHeadOfFamily() {
        return headOfFamily;
    }

    public void setHeadOfFamily(String headOfFamily) {
        this.headOfFamily = headOfFamily;
    }

    public Integer getNumberOfMembers() {
        return numberOfMembers;
    }

    public void setNumberOfMembers(Integer numberOfMembers) {
        this.numberOfMembers = numberOfMembers;
    }

    public String getFamilyAddress() {
        return familyAddress;
    }

    public void setFamilyAddress(String familyAddress) {
        this.familyAddress = familyAddress;
    }
}