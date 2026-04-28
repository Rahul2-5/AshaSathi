package com.Rahul.AshaSathi.service;

import com.Rahul.AshaSathi.dto.FamilyRegistrationRequest;
import com.Rahul.AshaSathi.dto.FamilyRegistrationResponse;
import com.Rahul.AshaSathi.dto.FamilyDetailsResponseDTO;
import com.Rahul.AshaSathi.dto.FamilyPatientResponseDTO;
import com.Rahul.AshaSathi.entity.Family;
import com.Rahul.AshaSathi.entity.FamilyPatient;
import com.Rahul.AshaSathi.repository.FamilyRepository;
import com.Rahul.AshaSathi.repository.FamilyPatientRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

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

    /**
     * Get all families with their members
     */
    @Transactional(readOnly = true)
    public List<FamilyDetailsResponseDTO> getAllFamilies() {
        return familyRepository.findAllByOrderByIdDesc()
                .stream()
                .map(this::mapFamilyToDetails)
                .toList();
    }

    /**
     * Get one family details by id
     */
    @Transactional(readOnly = true)
    public FamilyDetailsResponseDTO getFamilyDetailsById(Long familyId) {
        Family family = familyRepository.findById(familyId)
                .orElseThrow(() -> new RuntimeException("Family not found with id: " + familyId));

        return mapFamilyToDetails(family);
    }

    /**
     * Delete a family and all linked members
     */
    @Transactional
    public void deleteFamilyById(Long familyId) {
        if (!familyRepository.existsById(familyId)) {
            throw new RuntimeException("Family not found with id: " + familyId);
        }

        patientRepository.deleteByFamilyId(familyId);
        familyRepository.deleteById(familyId);
        log.info("Deleted family and members for familyId={}", familyId);
    }

    private FamilyDetailsResponseDTO mapFamilyToDetails(Family family) {
        List<FamilyPatientResponseDTO> patients = patientRepository
                .findByFamilyIdOrderByIdAsc(family.getId())
                .stream()
                .map(this::mapPatientToResponse)
                .toList();

        return FamilyDetailsResponseDTO.builder()
                .id(family.getId())
                .headOfFamily(family.getHeadOfFamily())
                .numberOfMembers(family.getNumberOfMembers())
                .familyAddress(family.getFamilyAddress())
                .patients(patients)
                .build();
    }

    private FamilyPatientResponseDTO mapPatientToResponse(FamilyPatient patient) {
        return FamilyPatientResponseDTO.builder()
                .id(patient.getId())
                .patientName(patient.getPatientName())
                .age(patient.getAge())
                .dateOfBirth(patient.getDateOfBirth())
                .gender(patient.getGender())
                .caste(patient.getCaste())
                .address(patient.getAddress())
                .phoneNumber(patient.getPhoneNumber())
                .isPregnant(patient.getIsPregnant())
                .monthsOfPregnancy(patient.getMonthsOfPregnancy())
                .expectedDeliveryDate(patient.getExpectedDeliveryDate())
                .photoPath(patient.getPhotoPath())
                .diseases(parseDiseasesMap(patient.getDiseases()))
                .declinedHealthInfo(patient.getDeclinedHealthInfo())
                .notes(patient.getNotes())
                .build();
    }

    private Map<String, Boolean> parseDiseasesMap(String diseasesJson) {
        if (diseasesJson == null || diseasesJson.isBlank()) {
            return Map.of();
        }

        try {
            return objectMapper.readValue(diseasesJson, new TypeReference<Map<String, Boolean>>() {});
        } catch (Exception e) {
            log.warn("Failed to parse diseases JSON for family patient: {}", e.getMessage());
            return Map.of();
        }
    }
}
