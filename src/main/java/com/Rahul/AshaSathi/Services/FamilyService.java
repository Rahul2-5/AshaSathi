package com.Rahul.AshaSathi.Services;

import com.Rahul.AshaSathi.DTO.FamilyRegistrationRequest;
import com.Rahul.AshaSathi.DTO.FamilyRegistrationResponse;
import com.Rahul.AshaSathi.Entity.Family;
import com.Rahul.AshaSathi.Entity.FamilyPatient;
import com.Rahul.AshaSathi.Repository.FamilyPatientRepository;
import com.Rahul.AshaSathi.Repository.FamilyRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FamilyService {

    private final FamilyRepository familyRepository;
    private final FamilyPatientRepository patientRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public FamilyRegistrationResponse registerFamily(FamilyRegistrationRequest request) {
        try {
            Family family = new Family();
            family.setHeadOfFamily(request.getFamilyInfo().getHeadOfFamily());
            family.setNumberOfMembers(request.getFamilyInfo().getNumberOfMembers());
            family.setFamilyAddress(request.getFamilyInfo().getFamilyAddress());

            Family savedFamily = familyRepository.save(family);
            int patientCount = 0;

            if (request.getPatients() != null) {
                for (var patientDto : request.getPatients()) {
                    FamilyPatient patient = new FamilyPatient();
                    patient.setFamily(savedFamily);
                    patient.setPatientName(patientDto.getPatientName());
                    patient.setAge(patientDto.getAge());
                    patient.setDateOfBirth(patientDto.getDateOfBirth());
                    patient.setGender(patientDto.getGender());
                    patient.setCaste(patientDto.getCaste());
                    patient.setAddress(patientDto.getAddress());
                    patient.setPhoneNumber(patientDto.getPhoneNumber());
                    patient.setIsPregnant(Boolean.TRUE.equals(patientDto.getIsPregnant()));
                    patient.setMonthsOfPregnancy(patientDto.getMonthsOfPregnancy());
                    patient.setExpectedDeliveryDate(patientDto.getExpectedDeliveryDate());
                    patient.setPhotoPath(patientDto.getPhotoPath());
                    patient.setDeclinedHealthInfo(Boolean.TRUE.equals(patientDto.getDeclinedHealthInfo()));
                    patient.setNotes(patientDto.getNotes());

                    if (patientDto.getDiseases() != null) {
                        try {
                            patient.setDiseases(objectMapper.writeValueAsString(patientDto.getDiseases()));
                        } catch (Exception e) {
                            patient.setDiseases("{}");
                        }
                    } else {
                        patient.setDiseases("{}");
                    }

                    patientRepository.save(patient);
                    patientCount++;
                }
            }

            return FamilyRegistrationResponse.builder()
                    .familyId(savedFamily.getId())
                    .message("Family registered successfully")
                    .patientCount(patientCount)
                    .status("SUCCESS")
                    .build();
        } catch (Exception e) {
            log.error("Error registering family", e);
            return FamilyRegistrationResponse.builder()
                    .message("Error: " + e.getMessage())
                    .status("ERROR")
                    .patientCount(0)
                    .build();
        }
    }

    public Family getFamilyById(Long familyId) {
        return familyRepository.findById(familyId)
                .orElseThrow(() -> new RuntimeException("Family not found with id: " + familyId));
    }
}