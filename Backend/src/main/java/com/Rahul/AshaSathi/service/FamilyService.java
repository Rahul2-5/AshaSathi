package com.Rahul.AshaSathi.service;

import com.Rahul.AshaSathi.dto.FamilyRegistrationRequest;
import com.Rahul.AshaSathi.dto.FamilyRegistrationResponse;
import com.Rahul.AshaSathi.entity.Family;
import com.Rahul.AshaSathi.entity.FamilyPatient;
import com.Rahul.AshaSathi.repository.FamilyRepository;
import com.Rahul.AshaSathi.repository.FamilyPatientRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * ============================================
 * FAMILY SERVICE
 * ============================================
 * Handles business logic for family registration
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FamilyService {
    
    private final FamilyRepository familyRepository;
    private final FamilyPatientRepository patientRepository;
    private final ObjectMapper objectMapper;
    
    /**
     * Register a new family with patients
     */
    @Transactional
    public FamilyRegistrationResponse registerFamily(FamilyRegistrationRequest request) {
        try {
            log.info("Registering family: {}", request.getFamilyInfo().getHeadOfFamily());
            
            // 1. Create family
            Family family = new Family();
            family.setHeadOfFamily(request.getFamilyInfo().getHeadOfFamily());
            family.setNumberOfMembers(request.getFamilyInfo().getNumberOfMembers());
            family.setFamilyAddress(request.getFamilyInfo().getFamilyAddress());
            
            Family savedFamily = familyRepository.save(family);
            log.info("Family created with ID: {}", savedFamily.getId());
            
            // 2. Create patients
            int patientCount = 0;
            if (request.getPatients() != null && !request.getPatients().isEmpty()) {
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
                    patient.setIsPregnant(patientDto.getIsPregnant() != null ? patientDto.getIsPregnant() : false);
                    patient.setMonthsOfPregnancy(patientDto.getMonthsOfPregnancy());
                    patient.setExpectedDeliveryDate(patientDto.getExpectedDeliveryDate());
                    patient.setPhotoPath(patientDto.getPhotoPath());
                    patient.setDeclinedHealthInfo(patientDto.getDeclinedHealthInfo() != null ? patientDto.getDeclinedHealthInfo() : false);
                    patient.setNotes(patientDto.getNotes());
                    
                    // Serialize diseases map to JSON
                    if (patientDto.getDiseases() != null) {
                        try {
                            String diseasesJson = objectMapper.writeValueAsString(patientDto.getDiseases());
                            patient.setDiseases(diseasesJson);
                        } catch (Exception e) {
                            log.warn("Failed to serialize diseases: {}", e.getMessage());
                            patient.setDiseases("{}");
                        }
                    } else {
                        patient.setDiseases("{}");
                    }
                    
                    patientRepository.save(patient);
                    patientCount++;
                }
            }
            
            log.info("Successfully registered family {} with {} patients", 
                    savedFamily.getId(), patientCount);
            
            return FamilyRegistrationResponse.builder()
                    .familyId(savedFamily.getId())
                    .message("Family registered successfully")
                    .patientCount(patientCount)
                    .status("SUCCESS")
                    .build();
                    
        } catch (Exception e) {
            log.error("Error registering family: {}", e.getMessage(), e);
            return FamilyRegistrationResponse.builder()
                    .message("Error: " + e.getMessage())
                    .status("ERROR")
                    .build();
        }
    }
    
    /**
     * Get family details by id
     */
    public Family getFamilyById(Long familyId) {
        return familyRepository.findById(familyId)
                .orElseThrow(() -> new RuntimeException("Family not found with id: " + familyId));
    }
}
