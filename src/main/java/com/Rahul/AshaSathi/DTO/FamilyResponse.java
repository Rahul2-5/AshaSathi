package com.Rahul.AshaSathi.DTO;

import java.util.List;
import java.util.Map;

public class FamilyResponse {
    private Long id;
    private String headOfFamily;
    private Integer numberOfMembers;
    private String familyAddress;
    private List<Map<String, Object>> patients;

    public FamilyResponse(
            Long id,
            String headOfFamily,
            Integer numberOfMembers,
            String familyAddress,
            List<Map<String, Object>> patients
    ) {
        this.id = id;
        this.headOfFamily = headOfFamily;
        this.numberOfMembers = numberOfMembers;
        this.familyAddress = familyAddress;
        this.patients = patients;
    }

    public Long getId() {
        return id;
    }

    public String getHeadOfFamily() {
        return headOfFamily;
    }

    public Integer getNumberOfMembers() {
        return numberOfMembers;
    }

    public String getFamilyAddress() {
        return familyAddress;
    }

    public List<Map<String, Object>> getPatients() {
        return patients;
    }
}
