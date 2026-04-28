package com.Rahul.AshaSathi.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FamilyInfoDTO {
    private String headOfFamily;
    private Integer numberOfMembers;
    private String familyAddress;
}